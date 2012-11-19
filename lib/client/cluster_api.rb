module OVIRT
  class Client
    def cluster_version(cluster_id)
      c = cluster(cluster_id)
      return c.version.split('.')[0].to_i, c.version.split('.')[1].to_i
    end

    def cluster_version?(cluster_id, major)
      c = cluster(cluster_id)
      c.version.split('.')[0] == major
    end

    def clusters(opts={})
      headers = {:accept => "application/xml; detail=datacenters"}
      if filtered_api
        http_get("/clusters", headers).xpath('/clusters/cluster').collect do |cl|
          cluster = OVIRT::Cluster.new(self,cl)
        end.compact
      else
        search= opts[:search] || ("datacenter=%s" % current_datacenter.name)
        http_get("/clusters?search=%s" % CGI.escape(search), headers).xpath('/clusters/cluster').collect do |cl|
          cluster = OVIRT::Cluster.new(self, cl)
          #the following line is needed as a work-around a bug in RHEV 3.0 rest-api
          cluster if cluster.datacenter.id == current_datacenter.id
        end.compact
      end
    end

    def cluster(cluster_id)
      headers = {:accept => "application/xml; detail=datacenters"}
      cluster_xml = http_get("/clusters/%s" % cluster_id, headers)
      OVIRT::Cluster.new(self, cluster_xml.root)
    end

    def networks(opts)
      cluster_id = opts[:cluster_id] || current_cluster.id
      http_get("/clusters/%s/networks" % cluster_id, http_headers).xpath('/networks/network').collect do |cl|
        OVIRT::Network.new(self, cl)
      end
    end
  end
end
