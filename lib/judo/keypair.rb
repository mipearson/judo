module Judo
  class Keypair
    attr_reader :name
    
    def initialize base, _name
      @base = base
      @name = _name
      raise if !name or name == ''
    end

    def create!
      material = @base.ec2.create_key_pair(name)[:aws_material]
      @base.s3_put(filename, material)
    end
    
    def exist?
      begin
        @base.ec2.describe_key_pairs([name])
        true
      rescue Aws::AwsError => e
        raise unless e.message.start_with?('InvalidKeyPair.NotFound')
        false
      end
    end
    
    def file(&blk)
      Tempfile.open(filename) do |file|
        file.write(@base.s3_get(filename))
        file.flush
        FileUtils.chmod(0600, file.path)
        blk.call(file.path)
      end
    end
    
    def filename
      name + ".pem"
    end
  end
end
      
      
      