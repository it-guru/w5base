#!/usr/bin/python3
import requests,json,urllib
from requests_ntlm import HttpNtlmAuth
import shutil
import sys, getopt, time
from sys import stdin
from time import sleep


class SharePointService:
   def __init__(self, server, site, auth, username, password):
      self.server = server
      self.site = site
      self.baseURL = server + site
      self.authURL = server + auth + site
      self.username = username
      self.password = password
      self.headers = {'accept':         "application/json;odata=verbose", \
                      'content-type':   "application/json;odata=verbose", \
                      'Accept-Language':"en-US"}
      
      ## Create session and authenticate
      self.session = requests.Session()
      self.session.auth = HttpNtlmAuth(self.username, self.password, \
                                       self.session)
      r={}
      response={}
      try:
         response = self.session.get(self.authURL, headers=self.headers)
      except:
        r['statuscode']="Bad Request"
        r['code']="400"
        nativeMessage="Session can not created"
        r['message']=nativeMessage
        print(json.dumps(r, sort_keys=True, indent=4))
        sys.exit(1)

     
      if response.status_code != 200:
        r['statuscode']=response.status_code
        r['code']=response.reason
        nativeMessage=response.text
        r['message']=nativeMessage
        print(json.dumps(r, sort_keys=True, indent=4))
        sys.exit(1)

      ## Get security token
      response = self.session.post(self.baseURL+'/_api/contextinfo', \
                                   headers=self.headers)
      if response.status_code == 200:
          response = json.loads(response.text)
          digest_value = \
             response['d']['GetContextWebInformation']['FormDigestValue']
          self.headers['X-RequestDigest'] = digest_value
      else:
          raise Exception('Invalid server response ', response)


   def getRequest(self,f):
       url = self.baseURL+ "/_api/"+f
       response = self.session.get(url, headers=self.headers)
       r={}
       if response.status_code == 200:
           response = json.loads(response.text)
           r['d']=response['d']
           r['statuscode']=200
           r['code']="OK"
           r['message']="OK"
       else:
           r['statuscode']=response.status_code
           r['statuscode']=404
           r['code']=response.reason
           nativeMessage=response.text
           try:
              message=json.loads(nativeMessage);
              r['message']=message['error']['message']['value']
           except:
              r['message']=nativeMessage

       print(json.dumps(r, sort_keys=True, indent=4))
       return (1)

def main(argv):
   USERNAME = sys.stdin.readline() 
   USERNAME = USERNAME.strip()

   PASSWORD = sys.stdin.readline() 
   PASSWORD = PASSWORD.strip()

   baseurl = ''
   site = ''
   try:
      opts, args = getopt.getopt(argv,"b:s:",["baseurl=","site="])
   except getopt.GetoptError:
      print('SharepointAPIJSONProxy.py ' + \
            '--baseurl=<url> --site=<site> --method=<method>')
      sys.exit(2)
   for opt, arg in opts:
      if opt in ("-s", "--site"):
         site = arg
      elif opt in ("-b", "--baseurl"):
         baseurl = arg

   # Create class
   share = SharePointService(baseurl, '/sites/' + site, \
                             '/_windows/default.aspx?ReturnUrl=', \
                             USERNAME, PASSWORD)
   callFunction=args[0]

   share.getRequest(callFunction)

if __name__ == "__main__":
   main(sys.argv[1:])


