"""
Jerry's Custom cloudlab set up

Instructions:
Nothing to do here, look into .sh if you would like
"""

import geni.portal as portal
import geni.rspec.pg as pg

pc = portal.Context()

pc.defineParameter("hw_type", "Hardware Type", portal.ParameterType.NODETYPE, "")

pc.defineParameter(
    "os_image",
    "Operating System Image",
    portal.ParameterType.STRING,
    "urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU24-64-STD",
    longDescription="go to https://www.cloudlab.us/images.php, find urns",
)

params = pc.bindParameters()
request = pc.makeRequestRSpec()

node = request.RawPC("dramhit")

if params.hw_type != "":
    node.hardware_type = params.hw_type

if params.os_image != "":
    node.disk_image = params.os_image

node.addService(pg.Execute(shell="bash", command="/local/repository/setup.sh"))

pc.printRequestRSpec(request)
