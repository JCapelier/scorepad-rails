namespace :tests do
  desc "Generate minimal model tests (associations + factory smoke)"
  task generate_min_models: :environment do
    Rails.application.eager_load!
    outdir = Rails.root.join("test", "models")
    FileUtils.mkdir_p(outdir)

    ActiveRecord::Base.descendants
      .reject { |m| m.abstract_class? || !m.table_exists? }
      .reject { |m| m.name.start_with?("ActiveStorage::", "ActionText::") }
      .sort_by(&:name)
      .each do |model|
        file = outdir.join("#{model.model_name.singular}_test.rb")
        belongs  = model.reflect_on_all_associations(:belongs_to)
        has_many = model.reflect_on_all_associations(:has_many)
        has_one  = model.reflect_on_all_associations(:has_one)
        habtm    = model.reflect_on_all_associations(:has_and_belongs_to_many)

        lines = []
        lines << 'require "test_helper"'
        lines << ""
        lines << "class #{model.name}Test < ActiveSupport::TestCase"
        lines << "  # Associations"
        belongs.each  { |a| lines << "  should belong_to(:#{a.name})" }
        has_one.each  { |a| lines << "  should have_one(:#{a.name})" }
        has_many.each { |a| lines << "  should have_many(:#{a.name})" }
        habtm.each    { |a| lines << "  should have_and_belong_to_many(:#{a.name})" }
        lines << ""
        lines << "  # Smoke: factory builds a valid #{model.name}"
        lines << "  test \"factory builds a valid #{model.name}\" do"
        lines << "    record = build(:#{model.model_name.singular})"
        lines << "    assert record.valid?, record.errors.full_messages.to_sentence"
        lines << "  end"
        lines << "end"
        lines << ""
        File.write(file, lines.join("\n"))
        puts "Wrote #{file}"
      end
  end
end
