require "mqrb"
require "thor"
require "fileutils"
require "erb"

module Mqrb
  @@config = Config.new

  class Cli < Thor
    package_name "mqrb-cli"

    #
    # = create-app
    #
    desc "create-app [project-directory]", "Create new Monocoque-Ruby apps."
    method_option "runtime-dir", {desc: "Set Monocoque-ruby runtime path.", default: ""}
    method_option "runtime", {desc: "Set Monocoque-ruby runtime name.", default: "mqrb"}

    def create_app(dir_pj)
      Mqrb::create_new_app(dir_pj, options)
    end

    #
    # = version
    #
    desc "version", "Show mqrb-cli versions."

    def version
      print "mqrb-cli: "
      puts VERSION
    end
  end

  private

  # = mkdir
  def self.mkdir(dir)
    puts "[MKDIR]: #{dir}"
    Dir.mkdir dir
  end

  # = cp
  def self.cp(src, dst)
    puts "[COPY]: #{File.basename(src)} => #{dst}"
    FileUtils.cp src, dst
  end

  # = cp_r
  def self.cp_r(src, dst)
    puts "[COPY]: #{File.basename(src)} => #{dst}"
    FileUtils.cp_r src, dst
  end

  # = cp_erb
  def self.cp_erb(src, dst)
    puts "[ERB]: #{File.basename(src)} => #{dst}"
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
  def self.create_new_app(dir_pj, opt)
    # check project name
    if Dir.exist? dir_pj # exist?
      puts "[ERROR] already exist #{dir_pj} directory."
      return
    elsif (dir_pj !~ /\A(\w|-)+\z/) # valid?
      puts "[ERROR] invalid project name. please use charactor '[A-Z][a-z][0-9]_-'"
      return
    end

    # set default config
    @@config.dir_pj = dir_pj
    @@config.dir_dist = File.expand_path("../..", __dir__) + "/dist"
    @@config.dir_runtime = opt["runtime-dir"].empty? ? "#{@@config.dir_dist}/runtime" : opt["runtime-dir"]
    @@config.runtime = opt["runtime"].empty? ? "mqrb" : opt["runtime"]
    @@config.loader = "#{@@config.dir_dist}/loader/mqrb.js"

    # check params
    raise "No such runtime directory #{@@config.dir_runtime}" unless Dir.exist?(@@config.dir_runtime)
    raise "No such runtime directory #{@@config.dir_runtime}/#{@@config.runtime}" unless Dir.exist?(@@config.dir_runtime + "/" + @@config.runtime)

    # input app name
    print "Full App Name: (MyApp) "
    @@config.name = STDIN.gets.chomp
    @@config.name = "MyApp" if (@@config.name.empty?)

    # === install ==

    # copy template
    cp_r "#{@@config.dir_runtime}/#{@@config.runtime}/template", @@config.dir_pj
    Dir.glob("#{@@config.dir_pj}/**/*.erb").each do |f|
      cp_erb f, "#{@@config.dir_pj}/#{File.basename(f, ".erb")}"
      FileUtils.rm f
    end

    # copy loader
    mkdir "#{@@config.dir_pj}/mqrb"
    cp @@config.loader, "#{@@config.dir_pj}/mqrb/mqrb.js"

    # copy mqrb-library
    cp_r "#{@@config.dir_runtime}/#{@@config.runtime}/asm", "#{@@config.dir_pj}/mqrb/"
    cp_r "#{@@config.dir_runtime}/#{@@config.runtime}/wasm", "#{@@config.dir_pj}/mqrb/"

    puts "[Success] Created #{@@config.name} Project to #{@@config.dir_pj}"
  end
end
