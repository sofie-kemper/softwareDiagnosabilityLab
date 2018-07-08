# -*- coding: utf-8 -*-
"""
Created on Fri Jul  6 18:11:06 2018

@author: SeRvU
"""
def get_class_label_names():
    return ['perfect', 'good', 'medium', 'bad']

def get_class_labels(targets):
    classLabels = []
    for entry in targets:
        if(entry == 1):
            classLabels.append(0)
            continue
        if(entry > 1 and entry < 5):
            classLabels.append(1)
            continue
        if(entry >= 5 and entry < 9):
            classLabels.append(2)
            continue
        if(entry >= 9):
            classLabels.append(3)
            continue
        print('ERROR: no class label could be assigned')
        return(None)
    return(classLabels)
    
def print_iterable(targets):
    for entry in targets:
        print(entry, end=' ')
    print('',end='\n')