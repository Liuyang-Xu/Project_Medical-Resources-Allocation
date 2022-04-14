function expert_Ce = calculate_Ce(RH)
% 计算专家诊断信心
Le = 30;% 专家能力水平

% 病情诊断结果DH，服从众数为RH的beta分布，形状参数为Le
a1 = (RH * Le - 2 * RH + 1)/(1 - RH);% 原文中alpha
DH = betarnd(a1,Le);% 根据beta分布得出随机数DH

% 专家诊断信心Ce，服从众数为Ce_m的beta分布，形状参数为Le
Ce_m = (15 * (RH ^ 2))/Le - (15 * RH)/Le + 1;
a2 = (Ce_m * Le - 2 * Ce_m + 1)/(1 - Ce_m);
expert_Ce = betarnd(a2,Le);
end