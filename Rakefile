require 'plist'

desc 'blow away development sqlite database'
task :destroy_db do
  File.delete(File.expand_path("~/Library/Containers/GLG.twIRCk/Data/Library/Application\ Support/GLG.TwIRCk/TwIRCk.storedata"))
end

desc 'tag a new release and push it to github'
task :release, [:component] do |t, args|
  unless ['major', 'minor', 'patch'].include?(args[:component])
    puts "You can only bump the major, minor or patch version number"
    puts "You specified #{args[:component].inspect}"
    exit 1
  end
 
  result = Plist::parse_xml('TwIRCk/TwIRCk-Info.plist')
  pieces = result['CFBundleShortVersionString'].split('.').map(&:to_i)
  
  if args[:component] == 'major'
    pieces.first += 1
  elsif args[:component] == 'minor'
    pieces[1] += 1
  elsif args[:component] == 'patch'
    pieces[2] += 1
  end

  new_version = pieces.map(&:to_s).join('.')
  result['CFBundleShortVersionString'] = new_version

  plist = File.open('TwIRCk/TwIRCk-Info.plist', 'w')
  plist.write(result.to_plist)
  plist.close

  system("git add . --all; git commit -m 'Bump version to #{new_version}'")
  system("git tag v#{new_version}")
  system("git push --tags") 
end

desc 'bump the version at the patch level'
task 'bump_patch' do
  Rake::Task[:release].invoke('patch')
end

desc 'bump the version at the minor level'
task 'bump_minor' do
  Rake::Task[:release].invoke('minor')
end

desc 'bump the version at the major level'
task 'bump_major' do
  Rake::Task[:release].invoke('major')
end
