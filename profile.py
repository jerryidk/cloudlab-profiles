"""
Jerry's Custom cloudlab set up 

Instructions:
Nothing to do here, look into .sh if you would like
"""	  

import geni.portal as portal
import geni.rspec.pg as pg

pc = portal.Context()

pc.defineParameter(
    "hw_type", 
    "Hardware Type", 
    portal.ParameterType.NODETYPE, 
    "", # Default is empty, allowing the user to pick, or the mapper to choose
    longDescription="Select a physical node type. The CloudLab UI will automatically populate this list based on the cluster's current inventory."
)

pc.defineParameter(
    "os_image",
    "Operating System Image",
    portal.ParameterType.IMAGE,
    "",
    longDescription="Select the base OS image. Ubuntu 24.04 (Kernel 6.8+) is the default."
)

params = pc.bindParameters()
request = pc.makeRequestRSpec()

node = request.RawPC('dramhit')

# 3. Apply the dynamic parameters
if params.hw_type != "":
    node.hardware_type = params.hw_type

node.disk_image = params.os_image

node.addService(pg.Execute(shell="bash", command="/local/repository/setup.sh"))

pc.printRequestRSpec(request)
