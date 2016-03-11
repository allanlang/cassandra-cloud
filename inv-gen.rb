require 'aws-sdk'

Aws.config.update({ region: 'eu-west-1' })

ec2 = Aws::EC2::Client.new

resp = ec2.describe_instances({ filters: [
                                           {name:"tag:environment",values:['cassandra']}
                                         ]})

inventory = []
bastion_ip = '?.?.?.?'

resp.reservations.each do |res|
  res.instances.each do |instance|
    inventory.push({ 
      'name' => instance.instance_id, 
      'role' => instance.tags.find{ |x| x.key.downcase == 'role'}.value, 
      'rack' => instance.placement.availability_zone, 
      'ip' => (instance.public_ip_address || instance.private_ip_address),
      'seed' => instance.tags.find{ |x| x.key.downcase == 'seed'} != nil
      })
  end
end

puts '[bastion]'
inventory.each do |instance|
  if instance['role'] == 'bastion'
    puts "#{instance['name']} ansible_host=#{instance['ip']} ansible_user=ec2-user"
    bastion_ip = instance['ip']
  end
end
puts ''
puts '[seeds]'
inventory.each do |instance|
  if instance['seed']
    rack = 'RAC1' # TODO - derive from AZ in instance['rack']
    puts "#{instance['name']} ansible_host=#{instance['ip']} data_center=DC1 rack=#{rack}"
  end
end
puts ''
puts '[nodes]'
inventory.each do |instance|
  if instance['role'] == 'cassandra-node' && !instance['seed']
    rack = 'RAC1' # TODO - derive from AZ in instance['rack']
    puts "#{instance['name']} ansible_host=#{instance['ip']} data_center=DC1 rack=#{rack}"
  end
end
puts ''
puts '[cassandra:children]'
puts 'seeds'
puts 'nodes'
puts ''
puts '[cassandra:vars]'
puts 'ansible_user=ec2-user'
puts "ansible_ssh_common_args='-o \"ProxyCommand ssh -A ec2-user@#{bastion_ip} -W %h:%p\"'"