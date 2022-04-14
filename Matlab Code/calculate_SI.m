function nurse_SI = calculate_SI(RH)
% 计算护士诊断决策
Ln = 10;% 护士能力水平

% 病情诊断结果DH，服从众数为RH的beta分布，形状参数为Ln
a1 = (RH * Ln - 2 * RH + 1)/(1 - RH);% 原文中alpha
DH = betarnd(a1,Ln);% 根据beta分布得出随机数DH

% 护士诊断信心DC，服从众数为DC_m的beta分布，形状参数为Ln
DC_m = (15 * (RH ^ 2))/Ln - (15 * RH)/Ln + 1;
a2 = (DC_m * Ln - 2 * DC_m + 1)/(1 - DC_m);
DC = betarnd(a2,Ln);

% 计算诊断决策
nurse_SI = 1 - DH + (1 - DC)^2;
end