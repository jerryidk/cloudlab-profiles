"""
Jerry's Custom cloudlab set up 

Instructions:
Nothing to do here, look into .sh if you would like
"""	  
import geni.portal as portal
import geni.rspec.pg as pg

pc = portal.Context()
request = pc.makeRequestRSpec()
node = request.RawPC('dramhit-amd')
node.hardware_type = 'd7615'
node.addService(pg.Execute(shell="bash", command="/local/repository/setup.sh"))
pc.printRequestRSpec(request)
