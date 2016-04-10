# data preprocessing
import warnings
warnings.filterwarnings("ignore")

import numpy as np
import sklearn.cross_validation as cv
from sklearn.grid_search import GridSearchCV
from collections import Counter

N_TRAIN = 522911

def loadData():
    # import data
    X = [list(map(int, x.split(',')[:-1])) for x in open('covtype.data').read().splitlines()]
    _Y = [x.split(',')[-1] for x in open('covtype.data').read().splitlines()]
    Y = [int(x) - 1 for x in _Y]
    
    xTrain, xTest, yTrain, yTest = cv.train_test_split(np.array(X), np.array(Y), train_size = N_TRAIN/len(X), random_state = 13)

    mean = xTrain.mean(axis=0)
    std = xTrain.std(axis=0)
    mean[10:] = 0.0 
    std[10:] = 1.0 
    xTrain = (xTrain - mean) / std 
    xTest = (xTest - mean) / std 

    return xTrain, xTest, yTrain, yTest

from sklearn.grid_search import GridSearchCV
from sklearn.ensemble import AdaBoostClassifier
from sklearn.multiclass import OneVsRestClassifier
from sklearn.ensemble import RandomForestClassifier
from sklearn.svm import LinearSVC

xTrain, xTest, yTrain, yTest = loadData()

adaboost = AdaBoostClassifier()
randomforest = RandomForestClassifier() 

ESTIMATORS = { 
    'SVM-OVA': LinearSVC(loss="squared_hinge", penalty="l2", C=1000, dual=False, tol=1e-3),
    'SVM-EXPLICIT': LinearSVC(loss="squared_hinge", penalty='l2', C=1000, dual=False, tol = 1e-3, multi_class='crammer_singer'),
    'BOOSTING-OVA': OneVsRestClassifier(estimator = adaboost),
    'BOOSTING-EXPLICIT': AdaBoostClassifier(),
    'RANDOMFOREST-OVA': OneVsRestClassifier(estimator = randomforest),
    'RANDOMFOREST-EXPLICIT': RandomForestClassifier(),
}
GRIDS = {
        'SVM-OVA': {
                        'C': [0.1, 1, 10, 100, 1000, 10000]
                },
        'SVM-EXPLICIT': {
                        'C': [0.1, 1, 10, 100, 1000, 10000]
                },
        'BOOSTING-OVA': {
                        'estimator__n_estimators': [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048]
                },
        'BOOSTING-EXPLICIT': {
                        'n_estimators': [2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048]
                },
        'RANDOMFOREST-OVA': {
                        'estimator__n_estimators': [2, 4, 8, 16, 32, 64, 128, 256]
                },
        'RANDOMFOREST-EXPLICIT': {
                        'n_estimators': [2, 4, 8, 16, 32, 64, 128, 256]
                },
}

print("Training Classifiers")
print("====================")
for name in ESTIMATORS:
    print("Training %s ... " % name)
    estimator = ESTIMATORS[name]
    CV = GridSearchCV(estimator, param_grid=GRIDS[name], cv=5, n_jobs=-1 , verbose = 4)
    CV.fit(xTrain, yTrain)
    print ("Model accuracy: " + str(CV.score(xTest, yTest)))