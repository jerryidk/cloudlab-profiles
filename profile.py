"""
Two machine of same node type connected by ethernet

Instructions:
 
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
)

params = pc.bindParameters()
request = pc.makeRequestRSpec()

# ==========================================
# Setup Node 1
# ==========================================
node1 = request.RawPC("node1")

if params.hw_type != "":
    node1.hardware_type = params.hw_type

if params.os_image != "":
    node1.disk_image = params.os_image

bs1 = node1.Blockstore("bs1", "/opt")
bs1.size = "0" # Use all remaining unallocated disk space
node1.addService(pg.Execute(shell="bash", command="/local/repository/setup.sh"))

# Create an Ethernet interface for Node 1
iface1 = node1.addInterface("eth1")


# ==========================================
# Setup Node 2
# ==========================================
node2 = request.RawPC("node2")

if params.hw_type != "":
    node2.hardware_type = params.hw_type

if params.os_image != "":
    node2.disk_image = params.os_image

# Note: Blockstore names must be unique across the experiment, so we use "bs2"
bs2 = node2.Blockstore("bs2", "/opt")
bs2.size = "0"
node2.addService(pg.Execute(shell="bash", command="/local/repository/setup.sh"))

# Create an Ethernet interface for Node 2
iface2 = node2.addInterface("eth1")


# ==========================================
# Setup the Ethernet Link
# ==========================================
# Create a point-to-point link connecting the two interfaces
link = request.Link("lan")
link.addInterface(iface1)
link.addInterface(iface2)

pc.printRequestRSpec(request)
