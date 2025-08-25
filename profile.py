"""
Jerry's Custom cloudlab set up 

Instructions:
Nothing to do here, look into .sh if you would like
"""	  
import geni.portal as portal
import geni.rspec.pg as pg

pc = portal.Context()
request = pc.makeRequestRSpec()

node = request.RawPC('flex14-node')
node.component_id = "urn:publicid:IDN+utah.cloudlab.us+node+flex14"
node.node_type = "fixed"
node.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU24-64-STD'

# Install and execute a script that is contained in the repository.
node.addService(pg.Execute(shell="bash", command="/local/repository/setup.sh"))

# Print the generated rspec
pc.printRequestRSpec(request)
