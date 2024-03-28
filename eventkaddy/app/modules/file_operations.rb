module FileOperations

  # directories should be an array of paths
  def self.create_directories permission_level, user, group, directories
    directories.each do |directory|
      Dir.mkdir(directory, permission_level) unless File.directory? directory
			# not sure why, but mk directory does not set permission level as you would expect
			File.chmod(permission_level, directory)
      if `cut -d: -f1 /etc/group`.match( group ) && `users`.match( user )
        FileUtils.chown(user, group, directory)
      else
        puts "WARN: user and group #{user}:#{group} did not exist and directory owner was not updated."
        puts "If deploy:deploy, this is probably because you are not in production, and it is safe to ignore."
      end
    end
  end

  def self.bundle_files dest, file_paths

    FileUtils.rm dest, :force => true

    FileUtils.mkdir_p dest.dirname unless File.directory? dest.dirname

    Zip::ZipFile.open dest, Zip::ZipFile::CREATE do |zipfile|
      file_paths.each do |file_path|
        if File.file? file_path

          zipfile.add file_path.basename, file_path

        end
      end
    end
    File.chmod 0644, dest
  end

  def self.bundle_directories dest, dirs, dirname_to_merge = false

    FileUtils.rm dest, :force => true

    Zip::ZipFile.open dest, Zip::ZipFile::CREATE do |zipfile|
      dirs.each do |dir|

        FileUtils.mkdir_p dir unless File.directory? dir

        Dir.foreach dir do |item|

          next if invalid_item? item

          dirname   = dirname_to_merge || dir.basename
          item_path = "#{dir}/#{item}"

          if File.file? item_path
            zipfile.add "#{dirname}/#{item}", item_path
          end

        end

      end
    end
    File.chmod 0644, dest
  end

  private

  def self.invalid_item? item
    !!(item =~ /
    ^\.$   # current directory
    |
    ^\.\.$ # previous directory
    |
    \.zip$ # zip archive
    |
    ^\.    # hidden file
    /x)
  end

end

