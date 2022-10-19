% @file binomial.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 08-Oct-2022
% @brief This implements a correlating predictor (n_pat,n_his) for seizure patterns. 
%

classdef correlating_predictor
    properties
        n_patterns = 4;
        n_history = 3;

        patterns_hisotry = [];
        b_predictors = [];
    end

    methods
        function obj = correlating_predictor(n_pat, n_his)
            obj.n_patterns = n_pat;
            obj.n_history = n_his;

            for index = 1:(obj.n_patterns^obj.n_history)
                recent_his = fix((index-1)/(obj.n_patterns^(obj.n_history-1)))+1;
                obj.b_predictors = [obj.b_predictors binomial_predictor(recent_his)];
            end

            obj.patterns_hisotry = ones(1,obj.n_history);
        end

        function pred = predict(obj)
            % make prediction
            pred_i = 1;
            for i = 1:obj.n_history
                pred_i = pred_i + (obj.patterns_hisotry(i)-1)*(obj.n_patterns^(obj.n_history-i));
            end
            pred = predict(obj.b_predictors(pred_i));
        end

        function updated_obj = update(obj, true_event)
            % Update
            pred_i = 1;
            for i = 1:obj.n_history
                pred_i = pred_i + (obj.patterns_hisotry(i)-1)*(obj.n_patterns^(obj.n_history-i));
            end
            obj.b_predictors(pred_i) = update(obj.b_predictors(pred_i), true_event);
            
            % Update history
            obj.patterns_hisotry = [true_event obj.patterns_hisotry];
            obj.patterns_hisotry = obj.patterns_hisotry(1:obj.n_history);

            updated_obj = obj;
        end
    end
end