require File.join(File.dirname(__FILE__), 'support', 'env')

describe Judo::Keypair do
  
  KEYPAIR_NAME = "my_keypair"
  
  before :each do
    @ec2 = stub("ec2")
    @base = stub("base", :ec2 => @ec2)

    @keypair = Judo::Keypair.new(@base, KEYPAIR_NAME)
  end
  
  describe :name do
    it "should be the keypair name" do
      @keypair.name.should == KEYPAIR_NAME
    end
  end
  
  describe :create! do
    it "should create the keypair in EC2 and upload it to S3" do
      @ec2.should_receive(:create_key_pair).with(KEYPAIR_NAME).and_return({:aws_material => "key contents"})
      @base.should_receive(:s3_put).with(@keypair.filename, 'key contents')
      
      @keypair.create!
    end
  end

  describe :filename do
    it "should return the s3 filename of the keypair" do
      @keypair.filename.should == KEYPAIR_NAME + '.pem'
    end
  end
    
  describe :exist? do
    it "should return true if the keypair can be describe in ec2" do
      @ec2.should_receive(:describe_key_pairs).with([KEYPAIR_NAME]).and_return(true)
      @keypair.exist?.should be_true
    end
    
    it "should return false if EC2 doesn't recognize the keypair" do
      @ec2.should_receive(:describe_key_pairs).with([KEYPAIR_NAME]).and_raise(Aws::AwsError.new('InvalidKeyPair.NotFound'))
      @keypair.exist?.should be_false
    end
    
    it "should allow other EC2 exceptions to propogate" do
      @ec2.should_receive(:describe_key_pairs).with([KEYPAIR_NAME]).and_raise(Aws::AwsError.new('Holy Shit!'))
      lambda {@keypair.exist?}.should raise_exception(/Holy Shit/)
    end
  end
  
  describe :file do
    it "should download the key from S3 and yield to the passed block with its path" do
      @base.should_receive(:s3_get).with(@keypair.filename).and_return("key contents")
      
      @keypair.file {|f| File.read(f)}.should == "key contents"
    end
  end
end