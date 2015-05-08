#!/usr/bin/python

import tornado.ioloop
import tornado.web
import tornado.httpclient

import pdb

flickrSearch = 'https://www.flickr.com/services/rest/?method=flickr.photos.getRecent&api_key=9787477e45fec5e4f16ab9cbb60c3447'

class MainHandler(tornado.web.RequestHandler):
    def get(self):
		self.write("Hello, MSLC World")

class GetExampleHandler(tornado.web.RequestHandler):
    def get(self):
    	print "received get request"
    	arg = self.get_argument("arg", None, True) # get the argument
    	if arg is None:
        	self.write("No 'arg' in query")
        else:
        	self.write(str(arg)) # spit back out the argument

class SearchHandler(tornado.web.RequestHandler):
	@tornado.web.asynchronous
	def get(self):
		self.write("Searching on Flickr!")
		http_client = tornado.httpclient.AsyncHTTPClient()
		response = http_client.fetch(flickrSearch,self.handle_response)    	

	def handle_response(self,response):
		# print response.body
		self.write(" and we got a response! \n\n")
		self.write(response.body.replace("<", " "))
		self.finish()
    	

application = tornado.web.Application([
    (r"/", MainHandler),
    (r"/GetExample", GetExampleHandler),
    (r"/Flickr",SearchHandler),
])

if __name__ == "__main__":
    application.listen(8888)
    tornado.ioloop.IOLoop.instance().start()
