"""
Jerry's Custom CloudLab Setup

Instructions:
Nothing to do here, look into .sh if you would like
"""
# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
import geni.rspec.pg as pg

# Create a portal context.
pc = portal.Context()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()

# Function to create a node
def create_node(request, node_name, hardware_type):
    node = request.RawPC(node_name)
    node.hardware_type = hardware_type
    node.disk_image = 'urn:publicid:IDN+emulab.net+image+emulab-ops:UBUNTU20-64-STD'
    node.addService(pg.Execute(shell="sh", command="/local/repository/setup.sh"))
    return node

# Array of hardware types
hardware_types = ['c220g5', 'c220g2']

# Create nodes based on hardware types
for i, hw_type in enumerate(hardware_types):
    create_node(request, f'node-{i}', hw_type)

# Print the generated RSpec
pc.printRequestRSpec(request)
