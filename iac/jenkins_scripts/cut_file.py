token=""
with open("jenkins_scripts/sonar-token.txt",'r') as f:
    content = f.readlines()
    for i in range(46, 86, 1):
        token=token + str(content)[i]

file = open('jenkins_scripts/sonar-token.txt', 'w')
file.write(token)
file.close()