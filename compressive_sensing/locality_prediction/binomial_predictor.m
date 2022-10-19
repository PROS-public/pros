% @file binomial.m
% @author  Nhat Pham <nhat.pham@cs.ox.ac.uk>.
% @version 1.0
% @date 08-Oct-2022
% @brief This implements a binomial predictor for seizure patterns. 
%

classdef binomial_predictor
    properties
        tbc_count = 2;
        tbc_pred;
    end

    methods
        function obj = binomial_predictor(init_val)
            obj.tbc_pred = init_val;
        end

        function pred = predict(obj)
            pred = obj.tbc_pred;
        end

        function updated_obj = update(obj, true_value)
            if true_value ~= obj.tbc_pred
                obj.tbc_count = obj.tbc_count - 1;
                if obj.tbc_count == 0
                    obj.tbc_count = 2;
                    obj.tbc_pred = true_value;
                end
            end
            updated_obj = obj;
        end
    end
end