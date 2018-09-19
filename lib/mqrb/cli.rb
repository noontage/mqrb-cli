require "mqrb"
require "thor"
require "fileutils"
require "erb"

module Mqrb
  @@app = {
    name: "MyApp",
    dir_pj: "myapp",
    dir_template: "dist/template",
    dir_library: "dist/mqrb-with-compiler",
    bundle_rb: "bundle.rb",
  }
  @@template = {}

  class Cli < Thor
    package_name "mqrb-cli"

    # = create-app
    desc "create-app [project-directory]", "Create new Monocoque Ruby apps."

    def create_app(dir_pj)
      Mqrb::create_new_app(dir_pj)
    end

    # = version
    desc "version", "Show mqrb-cli versions."

    def version
      puts VERSION
    end
  end

  private

  # = cp
  def self.cp(src, dst)
    puts "[COPY] => #{dst}"
    FileUtils.cp src, dst
  end

  # = cp_r
  def self.cp_r(src, dst)
    puts "[COPY] => #{dst}"
    FileUtils.cp_r src, dst
  end

  # = cp_erb
  def self.cp_erb(src, dst)
    puts "[COPY] => #{dst}"
    File.open(src) do |f|
      erb = ERB.new(f.read)
      File.open(dst, "w") do |f|
        begin
          f.puts erb.result(binding)
        rescue => e
          STDERR.puts "ERB Parse Error"
          raise e
        end
      end
    end
  end

  # = create_new_app
  def self.create_new_app(dir_pj)
    # check project name
    if Dir.exist? dir_pj # exist?
      puts "already exist #{dir_pj} directory."
      return
    elsif (dir_pj !~ /\A(\w|-)+\z/) # valid?
      puts "invalid project name. please use charactor '[A-Z][a-z][0-9]_-'"
      return
    else
      @@app[:dir_pj] = dir_pj
    end

    # set default souce template
    @@template[:index] = "#{@@app[:dir_template]}/index.html.erb" unless @@template[:index]
    @@template[:main_js] = "#{@@app[:dir_template]}/main.js.erb" unless @@template[:main_js]
    @@template[:bundle_rb] = "#{@@app[:dir_template]}/bundle.rb" unless @@template[:bundle_rb]
    @@template[:mqrb_main] = "#{@@app[:dir_template]}/mqrb.js" unless @@template[:mqrb_main]

    # input app name
    print "Full App Name: (MyApp) "
    @@app[:name] = STDIN.gets.chomp
    @@app[:name] = "MyApp" if (@@app[:name].empty?)

    # create directory
    Dir.mkdir @@app[:dir_pj]
    Dir.mkdir "#{@@app[:dir_pj]}/mqrb"

    # make index.html, main.js, bundle.rb
    cp_erb @@template[:index], "#{@@app[:dir_pj]}/index.html"
    cp_erb @@template[:main_js], "#{@@app[:dir_pj]}/main.js"
    cp @@template[:bundle_rb], "#{@@app[:dir_pj]}/bundle.rb"

    # copy mqrb-library
    cp @@template[:mqrb_main], "#{@@app[:dir_pj]}/mqrb/mqrb.js"
    cp_r "#{@@app[:dir_library]}/asm", "#{@@app[:dir_pj]}/mqrb/"
    cp_r "#{@@app[:dir_library]}/wasm", "#{@@app[:dir_pj]}/mqrb/"

    puts "[Success] Created #{@@app[:name]} Project to #{@@app[:dir_pj]}"
  end
end
