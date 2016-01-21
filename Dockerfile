FROM node:5-onbuild
MAINTAINER Octoblu <docker@octoblu.com>

EXPOSE 80

ADD https://meshblu.octoblu.com/publickey /usr/src/app/public-key.json

CMD [ "node", "command.js" ]
