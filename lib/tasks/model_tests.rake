require "fileutils"

namespace :tests do
  desc "Generate baseline Minitest model tests with shoulda-matchers"
  task generate_models: :environment do
    Rails.application.eager_load!

    outdir = Rails.root.join("test", "models")
    FileUtils.mkdir_p(outdir)

    connection = ActiveRecord::Base.connection

    ActiveRecord::Base.descendants
      .reject { |m| m.abstract_class? || !m.table_exists? }
      .sort_by(&:name)
      .each do |model|
        table = model.table_name
        cols  = model.columns_hash
        idxs  = connection.indexes(table)

        unique_by_col = idxs.select(&:unique).map(&:columns).flatten.uniq.map(&:to_s)

        belongs   = model.reflect_on_all_associations(:belongs_to)
        has_many  = model.reflect_on_all_associations(:has_many)
        has_one   = model.reflect_on_all_associations(:has_one)
        has_and_belongs_to_many = model.reflect_on_all_associations(:has_and_belongs_to_many)

        validators = model.validators.group_by do |v|
          v.class.name.split("::").last # "PresenceValidator", "UniquenessValidator", etc.
        end

        # Build lines
        klass_name  = "#{model.name}Test"
        file_name   = outdir.join("#{model.model_name.singular}_test.rb")

        lines = []
        lines << "require \"test_helper\""
        lines << ""
        lines << "class #{klass_name} < ActiveSupport::TestCase"
        lines << "  # Associations"
        belongs.each   { |a| lines << "  should belong_to(:#{a.name})" }
        has_one.each   { |a| lines << "  should have_one(:#{a.name})" }
        has_many.each  { |a| lines << "  should have_many(:#{a.name})" }
        has_and_belongs_to_many.each { |a| lines << "  should have_and_belong_to_many(:#{a.name})" }

        lines << "" if lines.last != ""
        lines << "  # Validations"

        # Presence validations discovered from validators
        (validators["PresenceValidator"] || []).each do |v|
          v.attributes.each { |attr| lines << "  should validate_presence_of(:#{attr})" }
        end

        # Length validations
        (validators["LengthValidator"] || []).each do |v|
          opts = []
          opts << "is_at_least(#{v.options[:minimum]})" if v.options[:minimum]
          opts << "is_at_most(#{v.options[:maximum]})"  if v.options[:maximum]
          v.attributes.each do |attr|
            if opts.empty?
              lines << "  should validate_length_of(:#{attr})"
            else
              lines << "  should validate_length_of(:#{attr}).#{opts.join('.')}"
            end
          end
        end

        # Numericality validations
        (validators["NumericalityValidator"] || []).each do |v|
          v.attributes.each do |attr|
            ns = "  should validate_numericality_of(:#{attr})"
            ns << ".only_integer" if v.options[:only_integer]
            lines << ns
          end
        end

        # Inclusion validations
        (validators["InclusionValidator"] || []).each do |v|
          next unless v.options[:in]
          v.attributes.each do |attr|
            lines << "  should validate_inclusion_of(:#{attr}).in_array(#{v.options[:in].inspect})"
          end
        end

        # Uniqueness: from validators
        (validators["UniquenessValidator"] || []).each do |v|
          v.attributes.each do |attr|
            scope = Array(v.options[:scope]).presence
            case_insensitive = v.options.fetch(:case_sensitive, true) == false
            line = "  should validate_uniqueness_of(:#{attr})"
            line << ".scoped_to(#{scope.map(&:inspect).join(', ')})" if scope
            line << ".case_insensitive" if case_insensitive
            lines << line
          end
        end

        # Uniqueness: also infer from DB unique indexes (catching cases without validator)
        unique_by_col.each do |col|
          next if (validators["UniquenessValidator"] || []).any? { |v| v.attributes.map(&:to_s).include?(col) }
          lines << "  should validate_uniqueness_of(:#{col})"
        end

        lines << ""
        lines << "  # Sanity build (ensures factory/quick create works)"
        lines << "  test \"factory builds a valid #{model.name}\" do"
        lines << "    record = defined?(FactoryBot) ? build(:#{model.model_name.singular}) : #{model.name}.new"
        lines << "    assert record.valid?, record.errors.full_messages.to_sentence"
        lines << "  end"
        lines << "end"
        lines << ""

        File.write(file_name, lines.join("\n"))
        puts "Wrote #{file_name}"
      end

    puts "Done."
  end
end
