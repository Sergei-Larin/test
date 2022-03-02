FROM ubuntu:20.04
RUN apt -y update && apt -y install nginx
CMD ["nginx", "-g", "daemon off;"]