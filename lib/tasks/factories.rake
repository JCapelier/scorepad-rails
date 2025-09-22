# lib/tasks/factories.rake
require "securerandom"
require "fileutils"

namespace :factories do
  desc "Generate FactoryBot factories for all models into test/factories"
  task generate: :environment do
    Rails.application.eager_load!

    outdir = Rails.root.join("test", "factories")
    FileUtils.mkdir_p(outdir)

    skip_tables = %w[schema_migrations ar_internal_metadata]
    connection  = ActiveRecord::Base.connection

    type_default = lambda do |col, name|
      case col.type
      when :string, :text
        if defined?(Faker)
          if name =~ /email/
            '"user@example.com"'
          elsif name =~ /name|title/
            'Faker::Lorem.words(number: 2).join(" ")'
          else
            'Faker::Lorem.unique.word'
          end
        else
          name =~ /email/ ? '"user@example.com"' : %("#{name}_\#{SecureRandom.hex(3)}")
        end
      when :integer, :bigint
        1
      when :decimal, :float
        0.0
      when :boolean
        false
      when :datetime, :timestamp
        'Time.current'
      when :date
        'Date.current'
      when :uuid
        'SecureRandom.uuid'
      when :json, :jsonb
        '{}'
      else
        %("#{name}_\#{SecureRandom.hex(2)}")
      end
    end

    ActiveRecord::Base.descendants
      .reject { |k| k.abstract_class? }
      .sort_by(&:name)
      .each do |model|
        table = model.table_name
        next if skip_tables.include?(table)
        next unless connection.table_exists?(table)

        cols = model.columns_hash
        pkey = model.primary_key.to_s

        unique_cols = connection.indexes(table).select(&:unique).flat_map(&:columns).map(&:to_s).uniq

        required_belongs_to = model.reflect_on_all_associations(:belongs_to).select do |assoc|
          fk_col = cols[assoc.foreign_key.to_s]
          fk_col && fk_col.null == false
        end

        factory_name = model.model_name.singular
        filename     = outdir.join("#{table}.rb")

        puts "Generating #{filename}..."

        lines = []
        lines << "FactoryBot.define do"
        lines << "  factory :#{factory_name} do"

        required_belongs_to.each do |assoc|
          lines << "    association :#{assoc.name}"
        end

        if cols.key?("email")
          if unique_cols.include?("email")
            lines << '    sequence(:email) { |n| "user#{n}@example.com" }'
          else
            lines << '    email { "user@example.com" }'
          end
        end
        if cols.key?("password")
          lines << '    password { "password123" }'
        end
        if cols.key?("encrypted_password")
          lines << '    password { "password123" }'
        end

        cols.each do |name, col|
          next if name == pkey || %w[created_at updated_at].include?(name)
          next if required_belongs_to.any? { |a| a.foreign_key.to_s == name }
          next if %w[email password encrypted_password].include?(name)

          if unique_cols.include?(name)
            if [:string, :text].include?(col.type)
              base = (name =~ /email/) ? 'user' : name
              lines << "    sequence(:#{name}) { |n| \"#{base}_\#{n}\" }"
            elsif [:integer, :bigint].include?(col.type)
              lines << "    sequence(:#{name}) { |n| n }"
            else
              lines << "    sequence(:#{name}) { |n| \"#{name}_\#{n}\" }"
            end
          else
            default = type_default.call(col, name)
            lines << "    #{name} { #{default} }" unless col.null && col.default.nil?
          end
        end

        lines << "  end"
        lines << "end"

        File.write(filename, lines.join("\n") + "\n")
      end

    puts "Done. Review files under test/factories/."
  end
end
