require 'mkmf'

HERE = File.expand_path(File.dirname(__FILE__))
BUNDLE = Dir.glob("#{HERE}/pHash-*.tar.gz").first
BUNDLE_PATH = BUNDLE.gsub(".tar.gz", "")
$CFLAGS = " -x c++ #{ENV["CFLAGS"]}"
$includes = " -I#{HERE}/include"
$libraries = " -L#{HERE}/lib -L/usr/local/lib -L/opt/homebrew/lib"
$LIBPATH = ["#{HERE}/lib"]
$CFLAGS = "#{$includes} #{$libraries} #{$CFLAGS}"
$CFLAGS = "#{$CFLAGS} -fdeclspec" if RUBY_PLATFORM =~ /arm64-darwin/
$LDFLAGS = "#{$libraries} #{$LDFLAGS}"
$LDFLAGS = "#{$LDFLAGS} -L/opt/homebrew/opt/libjpeg/lib -L/opt/homebrew/opt/libpng/lib" if RUBY_PLATFORM =~ /arm64-darwin/
$CXXFLAGS = ' -pthread'
$CXXFLAGS = "#{$CXXFLAGS} -I/opt/homebrew/include/libpng16 -I/opt/homebrew/include" if RUBY_PLATFORM =~ /arm64-darwin/

Dir.chdir(HERE) do
  if File.exist?("lib")
    puts "pHash already built; run 'rake clean' first if you need to rebuild."
  else

    puts(cmd = "tar xzf #{BUNDLE} 2>&1")
    raise "'#{cmd}' failed" unless system(cmd)

    Dir.chdir(BUNDLE_PATH) do
      puts(cmd = "env CXXFLAGS='#{$CXXFLAGS}' CFLAGS='#{$CFLAGS}' LDFLAGS='#{$LDFLAGS}' ./configure --prefix=#{HERE} --disable-audio-hash --disable-video-hash --disable-shared --with-pic 2>&1")
      raise "'#{cmd}' failed" unless system(cmd)

      puts(cmd = "make || true 2>&1")
      raise "'#{cmd}' failed" unless system(cmd)

      puts(cmd = "make install || true 2>&1")
      raise "'#{cmd}' failed" unless system(cmd)

      puts(cmd = "mv CImg.h ../include 2>&1")
      raise "'#{cmd}' failed" unless system(cmd)
    end

    system("rm -rf #{BUNDLE_PATH}") unless ENV['DEBUG'] or ENV['DEV']
  end

  Dir.chdir("#{HERE}/lib") do
    system("cp -f libpHash.a libpHash_gem.a")
    system("cp -f libpHash.la libpHash_gem.la")
  end
  $LIBS = " -lpthread -lpHash_gem -lstdc++ -ljpeg -lpng"
end

have_header 'sqlite3ext.h' unless RUBY_PLATFORM =~ /arm64-darwin/

create_makefile 'phashion_ext'
