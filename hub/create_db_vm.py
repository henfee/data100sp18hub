#!/usr/bin/python

import json
import sys
import subprocess

if len(sys.argv) < 3:
	print("""Usage: {prog} SUBSCRIPTION RESOURCE_GROUP NODE_NAME

  example: {prog} foo bar data100sp18-prod-db9""".format(prog=sys.argv[0]))
	sys.exit(1)

subscription = sys.argv[1]
resource_group = sys.argv[2]
node_name = sys.argv[3]

# Set our subscription
subprocess.check_call(['az', 'account', 'set', '--subscription', subscription])

# parse our template and secrets
creds = json.loads(open('secrets/node_creds.json').read())
params = json.loads(open('secrets/parameters.json').read())
parameters = params['parameters']

# splice everything together
for k in creds.keys(): parameters[k]['value'] = creds[k]
parameters['virtualMachineName']['value'] = node_name
parameters['networkInterfaceName']['value'] = node_name + '-1'
parameters['publicIpAddressName']['value'] = node_name + '-ip'
parameters['networkSecurityGroupName']['value'] = node_name + '-nsg'

subprocess.check_call(['az', 'group', 'deployment', 'create',
	'--name', node_name,
	'--resource-group', resource_group,
	'--template-file', 'secrets/template.json',
	'--parameters', parameters
])

#with tempfile.NamedTemporaryFile(mode='w') as fp:
#	fp.write(json.dumps(parameters, indent=4, separators=(',',': ')))
#	subprocess.check_call(['az', 'group', 'deployment', 'create',
#		'--name', node_name,
#		'--resource-group', resource_group,
#		'--template-file', 'secrets/template.json',
#		'--parameters', '@' + fp.name
#	])
