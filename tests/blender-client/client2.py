from clientsocket import ClientSocket

s1 = ClientSocket("localhost", 5000, single_use=False)
response = s1.send("Hello, World!")