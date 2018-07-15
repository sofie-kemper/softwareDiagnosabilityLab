# -*- coding: utf-8 -*-
"""
Created on Fri Jul  6 18:11:06 2018

@author: SeRvU
"""
def get_class_names():
    return ['perfect', 'good', 'medium', 'useless']

def get_coarse_grained_class_names():
    return ['useful', 'useless']

def get_class_labels(targets):
    classLabels = []
    for entry in targets:
        if(entry == 1):
            classLabels.append(0)
            continue
        if(entry > 1 and entry < 5):
            classLabels.append(1)
            continue
        if(entry >= 5 and entry < 12):
            classLabels.append(2)
            continue
        if(entry >= 12):
            classLabels.append(3)
            continue
        print('ERROR: no class label could be assigned')
        return(None)
    return(classLabels)

""" prints an iterable, e.g. a list. Prevents that elements are skipped with '...'
    in large lists.         """
def print_iterable(targets):
    for entry in targets:
        print(entry, end=' ')
    print('',end='\n')
    
def get_class_labels_coarse_grained(targets):
    classLabels = []
    for entry in targets:
        if(entry <= 11):
            classLabels.append(0)
            continue
        if(entry >= 12):
            classLabels.append(1)
            continue
        print('ERROR: no class label could be assigned')
        return(None)
    return(classLabels)