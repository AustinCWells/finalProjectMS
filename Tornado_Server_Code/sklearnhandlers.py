#!/usr/bin/python

from pymongo import MongoClient
import tornado.web
from tornado import gen
import sys

from tornado.web import HTTPError
from tornado.httpserver import HTTPServer
from tornado.ioloop import IOLoop
from tornado.options import define, options

from basehandler import BaseHandler

from sklearn.neighbors import KNeighborsClassifier
import pickle
from bson.binary import Binary
import json
import uuid
from PIL import Image
from StringIO import StringIO
import numpy as np
from sklearn import svm
from sklearn import linear_model
from sklearn.decomposition import RandomizedPCA
from sklearn.preprocessing import StandardScaler


#dimensionality reduction function for large image into a one dimensional array
def processImage(imgData):
	STANDARD_SIZE = (15, 15)
        f = StringIO(imgData.decode('base64'))
        img = Image.open(f)
        img = img.getdata()
        img = img.resize(STANDARD_SIZE)
        img = map(list, img)
        img = np.array(img)
        s = img.shape[0] * img.shape[1]
        img_wide = img.reshape(1, s)
	img = img_wide[0]
	img[:] = [abs(x-225) for x in img]
	img = np.where(img>30, 1, 0)	

	return img



class UploadLabeledDatapointHandler(BaseHandler):
	def post(self):
		'''Save data point and class label to database
		'''
		data = json.loads(self.request.body)	
		
		vals = data['feature'];
		fvals = [int(val) for val in processImage(vals)]
		label = data['label'];
		sess  = data['dsid']
		
		try:
			dbid = self.db.labeledinstances.insert({"feature":fvals,"label":label,"dsid":sess});
			self.write_json({"id":str(dbid),"feature":fvals,"label":label});
		except:
			print("DBERROR OCCURED")
			self.write_json({"id":"ERROR","feature":fvals,"label":label});
		#self.client.close()

class RequestNewDatasetId(BaseHandler):
	def get(self):
		'''Get a new dataset ID for building a new dataset
		'''
		a = self.db.labeledinstances.find_one(sort=[("dsid", -1)])
		newSessionId = float(a['dsid'])+1;
		self.write_json({"dsid":str(newSessionId)})
		#self.client.close()


class UpdateModelForDatasetId(BaseHandler):


	@gen.coroutine
	def get(self):
		'''Train a new model (or update) for given dataset ID
		'''
		try:
			dsid = self.get_int_arg("dsid",default=0);
			option = self.get_int_arg("option",default=0);
			kNeighbors = self.get_int_arg("kNeighbors",default=3);
			# create feature vectors from database
			f=[];
			for a in self.db.labeledinstances.find({"dsid":dsid}): 
				f.append([int(val) for val in a['feature']])

			# create label vector from database
			l=[];
			for a in self.db.labeledinstances.find({"dsid":dsid}): 
				l.append(a['label'])

			# choose classifier
			if option is 0:
				# use kneighbors classifier
				c1 = KNeighborsClassifier(kNeighbors)
				print("MODEL UPDATED USING KNN")
			else:
				#using a support vector machine
				#c1 = svm.LinearSVC() 
				#print("MODEL UPDATED USING A LINEAR SVM")
				c1 = linear_model.LogisticRegression(C=1e5)
				print("MODEL UPDATED!")

			# if training takes a while, we are blocking tornado!! No!!
			# fit the model to the data
			if l:
				c1.fit(f,l); # training
				lstar = c1.predict(f);
				self.clf = c1;
				acc = sum(lstar==l)/float(len(l));
				bytes = pickle.dumps(c1);
				self.db.models.update({"dsid":dsid},{  "$set": {"model":Binary(bytes)}  },upsert=True)
			else:
				# initialize accuracy in case DSID is not found 
				acc = -1;
		except TypeError as detail:
			print(detail)
			print("DB ERROR ******* CANNOT UPDATE MODEL")
                	acc = 0.0
		# send back the resubstitution accuracy
		self.write_json({"resubAccuracy":acc})
		#self.client.close()

class PredictOneFromDatasetId(BaseHandler):
	def post(self):
		'''Predict the class of a sent feature vector
		'''
		data = json.loads(self.request.body)	

		vals = data['feature'];
		fvals = [int(val) for val in processImage(vals)]
		#print(str(fvals))
		dsid  = data['dsid']
		prob = 0
		#upload = data['upload']
		
		try:
			# load the model from the database (using pickle)
			if(self.clf == []):
				print 'Loading Model From DB'
				tmp = self.db.models.find_one({"dsid":dsid})
				self.clf = pickle.loads(tmp['model'])
			predLabel = self.clf.predict(fvals);
			myPrediction = predLabel[0].encode('utf-8')
			prob = self.clf.predict_proba(fvals)	
		except:
			print("DBERROR COULD NOT LOAD DATA POINT INTO DB")
			myPrediction = "E".encode('utf-8')
		prob = max(max(prob))	
		print(prob)
		print(self.clf.classes_)
		print(myPrediction)
		self.write_json({"prediction":myPrediction, "prob":prob})
		#self.client.close()













