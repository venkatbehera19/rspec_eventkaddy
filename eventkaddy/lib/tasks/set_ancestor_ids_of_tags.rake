namespace :set_ancestor_ids_of_tags do
  desc "The task will check for any existing inheritance in tags and populate the ancestor_ids column based on it"
  task :check_and_populate => :environment do
    puts "This will take sometime. Do not halt until it's done."
    Tag.in_batches do |tags|
      tags.each do |tag|
        temp_tag = tag
        result = ""
        while(temp_tag.parent) do
          temp_tag = temp_tag.parent
          result.prepend(temp_tag.ancestor_id_separator, temp_tag.id.to_s, temp_tag.ancestor_id_separator)
        end
        tag.update_column(:ancestor_ids, result) unless result.blank?
      end
    end
    puts "Done!"
  end
end
