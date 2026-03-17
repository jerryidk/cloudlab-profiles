"""
Jerry's Custom cloudlab set up 

Instructions:
Nothing to do here, look into .sh if you would like
"""	  
import geni.portal as portal
import geni.rspec.pg as pg


pc = portal.Context()

# 1. Define a parameter to choose the hardware type in the CloudLab UI
pc.defineParameter(
    "hw_type", 
    "Hardware Type", 
    portal.ParameterType.STRING, 
    "d7615",
    [("d7615", "d7615 (Utah cluster)"), ("r6615", "r6615 (Clemson cluster)")],
    "Select the hardware type for your single node."
)

# 2. Bind the parameters so you can use them in the script
params = pc.bindParameters()

request = pc.makeRequestRSpec()

node = request.RawPC('dramhit-amd')

# 3. Assign the user-selected parameter to the node's hardware_type
node.hardware_type = params.hw_type
node.addService(pg.Execute(shell="bash", command="/local/repository/setup.sh"))

pc.printRequestRSpec(request)
