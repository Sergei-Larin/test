#Image from DockerHub
FROM python:3.9
#Working dir in docker image
WORKDIR /app
# We copy just the requirements.txt first to leverage Docker cache
COPY requirements.txt /app
RUN pip3 install --upgrade pip -r requirements.txt
#Copy project files in docker image
COPY . /app
#set up applicaion port
EXPOSE 5000
#set entrypoint
ENTRYPOINT [ "python" ]
#run application
CMD [ "start.py" ]
