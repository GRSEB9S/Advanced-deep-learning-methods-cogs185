function [acc, acc_train, m_time_train] = test_hypertext(M, numIter)
% This function performs the hypertext classification task using the
%   fixed-point model 
% Inputs: 
%   M               the order-of context
%   numIter         the number of iterations 
% Outputs:
%   acc:            the accuracy
%   acc_train:      the training accuracy
%   m_time_train:   the training time
%

global cval; 

load dataToUse

numData = size(data, 2); 
dim = size(data, 1); 

labels = theLabels; 
labels(theLabels == 2) = 1;
labels(theLabels == 3) = 2;
labels(theLabels == 4) = 3;
labels(theLabels == 6) = 4;

schools = unique(theSchool); 

[otlk, inlk] = extend_link(numData, M, in_link2, out_link2); 

data = data_norm; 

acc_mat = []; 
num_mat = [];
acc_mat_train = [];
num_mat_train = []; 
time_test_mat = []; 
time_train_mat = []; 
for i = 1 : length(schools)
    allIdx = 1 : numData;
    idx = find(theSchool == schools(i));
    testIdx = allIdx(idx);
    allIdx(idx) = [];
    
    label_1 = labels;
    label_2 = labels;
    label_1(testIdx) = -1;
    label_2(allIdx) = -1;
 
    tic, 
    featMat1 = extend_context_hyper(label_1, 5, allIdx, inlk, otlk, M); 
    model = llsvmtrain(labels(allIdx), [data(:, allIdx)', featMat1'], ['-s 1 -c ' num2str(cval)]);
    time_train = toc; 
    
    time_train_mat = [time_train_mat, time_train]; 
    

    % predict the testing data 
    tic
    [accuracy_test] = iterative_prediction(numIter, model, data(:, testIdx), testIdx, labels, inlk, otlk, M);
    time_test = toc; 
    
    time_test_mat = [time_test_mat, time_test]; 
    
    % predict the training data 
    tic
    [accuracy_train] = iterative_prediction(numIter, model, data(:, allIdx), allIdx, labels, inlk, otlk, M);
    time_verify_train = toc; 

    acc_mat = [acc_mat, accuracy_test];
    num_mat = [num_mat, length(testIdx)];
    acc_mat_train = [acc_mat_train, accuracy_train]; 
    num_mat_train = [num_mat_train, length(allIdx)]; 
end

disp('testing error')
acc = sum(acc_mat .* num_mat) / sum(num_mat); 
disp(acc)
disp('training error')
acc_train = mean(sum(acc_mat_train .* num_mat_train) / sum(num_mat_train)); 
disp(acc_train)
disp('training time')
m_time_train = mean(time_train_mat); 
disp(m_time_train)
disp('testing time')
m_time_test = mean(time_test_mat); 
disp(m_time_test)

function [acc, acc_mat, pred_mat] = iterative_prediction(numIter, model, data, dataIdx, labels, inlk, otlk, M)

acc_mat = []; 
pred_mat = []; 

new_labels = labels; 
new_labels(:) = -1;

for iter = 1 : numIter
    featMat2 = extend_context_hyper(new_labels, 5, dataIdx, inlk, otlk, M);
    [predict_test, accuracy_test] = llsvmpredict(labels(dataIdx), [data', featMat2'], model);
    new_labels(dataIdx) = predict_test; 
    
    acc_mat = [acc_mat, accuracy_test];
end
acc = accuracy_test;