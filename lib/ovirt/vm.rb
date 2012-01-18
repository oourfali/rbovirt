module OVIRT
    # NOTE: Injected file will be available in floppy drive inside
    #       the instance. (Be sure you 'modprobe floppy' on Linux)
    FILEINJECT_PATH = "user-data.txt"

  class VM < BaseObject
    attr_reader :description, :status, :memory, :profile, :display, :host, :cluster, :template, :nics
    attr_reader :storage, :cores, :creation_time, :os, :ip, :vnc
    attr_accessor :nics, :disks

    def initialize(client, xml)
      super(client, xml[:id], xml[:href], (xml/'name').first.text)
      parse_xml_attributes!(xml)
      self
    end

    def running?
      @status =~ /up/i
    end

    def self.to_xml(template_name, cluster_name, opts={})
      builder = Nokogiri::XML::Builder.new do
        vm{
          name_ opts[:name] || "i-#{Time.now.to_i}"
          template_{
            name_(template_name)
          }
          cluster_{
            name_(cluster_name)
          }
          type_ opts[:hwp_id] || 'Server'
          memory opts[:hwp_memory] ? (opts[:hwp_memory].to_i*1024*1024).to_s : (512*1024*1024).to_s
          cpu {
            topology( :cores => (opts[:hwp_cpu] || '1'), :sockets => '1' )
          }
          os{
            boot(:dev=>'network')
            boot(:dev=>'hd')
          }
          display_{
            type_('vnc')
          }
          if(opts[:user_data] && !opts[:user_data].empty?)
            custom_properties {
              custom_property({
                :name => "floppyinject",
                :value => "#{OVIRT::FILEINJECT_PATH}:#{opts[:user_data]}",
                :regexp => "^([^:]+):(.*)$"})
            }
          end
        }
      end
      Nokogiri::XML(builder.to_xml).root.to_s
    end

    private

    def parse_xml_attributes!(xml)
      @description = ((xml/'description').first.text rescue '')
      @status = ((xml/'status').first.text rescue 'unknown')
      @memory = (xml/'memory').first.text
      @profile = (xml/'type').first.text
      @template = Link::new(@client, (xml/'template').first[:id], (xml/'template').first[:href])
      @host = Link::new(@client, (xml/'host').first[:id], (xml/'host').first[:href]) rescue nil
      @cluster = Link::new(@client, (xml/'cluster').first[:id], (xml/'cluster').first[:href])
      @display = {
        :type => (xml/'display/type').first.text,
        :address => ((xml/'display/address').first.text rescue nil),
        :port => ((xml/'display/port').first.text rescue nil),
        :monitors => (xml/'display/monitors').first.text
      }
      @cores = ((xml/'cpu/topology').first[:cores] rescue nil)
      @storage = ((xml/'disks/disk/size').first.text rescue nil)
      @creation_time = (xml/'creation_time').text
      @ip = ((xml/'guest_info/ip').first[:address] rescue nil)
      @vnc = {
        :address => ((xml/'display/address').first.text rescue "127.0.0.1"),
        :port => ((xml/'display/port').first.text rescue "5890")
      } unless @ip
      @os = {
          :type => (xml/'os').first[:type],
          :boot => (xml/'os/boot').collect {|boot| boot[:dev] }
      }
    end

  end
end