function RH = calculate_RH(patient_real,patient,sigma_1,T)
% 计算病人健康状况
H0 = patient.H0(patient_real);% 病人初始生理状况
sigma = sigma_1(patient_real);% 每个病人的恶化率
t = T - patient.arrival(patient_real);% 病人等待时间
H = H0 - sigma.*t;% T时刻的生理状态


% 原文的死亡条件非常严苛，尝试过程中没有达到的
%{
RH = zeros(length(patient_real),1);
for i = 1:length(patient_real)
    if t(i) >= H0(i)/sigma(i)
        RH(i) = 0;
    else
        RH(i) = H(i)/(1 + 10000*(sigma(i)^2));% T时刻的健康状态
    end
end
%}

% 故改为下方这种死亡判定方式
RH = H./(1 + 10000*(sigma.*sigma));% T时刻的健康状态
RH(RH<0.35) = 0;% 0.35是一个经试验后较贴合实际情况的阈值，可根据实际情况更改

end