clear,clc;
% 医疗资源
nurse.n_total = 9;
doctor.n_total = 12;
expert.n_total = 8;
check.n_total = 4;

% 不同方案下的PN与K值
PN1_scheme = [50;100;150];
PN2_scheme = [50;100;150];
k1_scheme = [0.4;0.6;0.8];
k2_scheme = [0.8;1.0;1.2];

scheme_length = length(PN1_scheme)*length(PN2_scheme)*length(k1_scheme)*length(k2_scheme);
scheme = zeros(scheme_length , 4);% 所有不同方案矩阵
count = 1;
for i = 1:length(PN1_scheme)
    for j = 1:length(PN2_scheme)
        for m = 1:length(k1_scheme)
            for n = 1:length(k2_scheme)
                scheme(count,1) = i;
                scheme(count,2) = j;
                scheme(count,3) = m;
                scheme(count,4) = n;
                count = count + 1;
            end
        end
    end
end

% 评价指标惩罚系数
tao1 = 0.5;
tao2 = 0.5;

% 方案1：PN1:PN2
DR = zeros(scheme_length,1);
AS = zeros(scheme_length,1);
for scheme_i = 1:scheme_length
    PN1 = scheme(scheme_i,1);% 常规病人数量
    PN2 = scheme(scheme_i,2);% 突发病人数量
    k1 = scheme(scheme_i,3);% 常规病人恶化率系数
    k2 = scheme(scheme_i,4);% 突发病人恶化率系数
    
    method_1 = PN1/PN2;% 方案1
    
    nurse_n_2 = round(nurse.n_total/(method_1 + 1));% 突发病人区护士数量
    doctor_n_2 = round(doctor.n_total/(method_1 + 1));
    expert_n_2 = round(expert.n_total/(method_1 + 1));
    check_n_2 = round(check.n_total/(method_1 + 1));
    nurse_n_1 = nurse.n_total - nurse_n_2;% 常规病人区护士数量
    doctor_n_1 = doctor.n_total - doctor_n_2;% 常规病人区医生数量
    expert_n_1 = expert.n_total - expert_n_2;% 常规病人区专家数量
    check_n_1 = check.n_total - check_n_2;% 常规病人区检查设备数量
    
    [DR1 , AS1] = medical_distribution(PN1 , k1, nurse_n_1, doctor_n_1, expert_n_1, check_n_1);% 常规病人
    [DR2 , AS2] = medical_distribution(PN2 , k2, nurse_n_2, doctor_n_2, expert_n_2, check_n_2);% 突发病人
    DR(scheme_i) = (DR1*PN1 + DR2*PN2)/(PN1 + PN2);% 死亡率
    AS(scheme_i) = (AS1*PN1 + AS2*PN2)/(PN1 + PN2);% 平均系统逗留时间
end
DR_std = mean(DR);
AS_std = mean(AS);
f_method_1 = tao1 * (DR - DR_std)/DR_std + tao2 * (AS - AS_std)/AS_std;% 原文评价指标

% 方案2：k1:k2
DR = zeros(scheme_length,1);
AS = zeros(scheme_length,1);
for scheme_i = 1:scheme_length
    PN1 = scheme(scheme_i,1);% 常规病人数量
    PN2 = scheme(scheme_i,2);% 突发病人数量
    k1 = scheme(scheme_i,3);% 常规病人恶化率系数
    k2 = scheme(scheme_i,4);% 突发病人恶化率系数
    
    method_2 = k1/k2;% 方案2
    
    nurse_n_2 = round(nurse.n_total/(method_2 + 1));% 突发病人区护士数量
    doctor_n_2 = round(doctor.n_total/(method_2 + 1));
    expert_n_2 = round(expert.n_total/(method_2 + 1));
    check_n_2 = round(check.n_total/(method_2 + 1));
    nurse_n_1 = nurse.n_total - nurse_n_2;% 常规病人区护士数量
    doctor_n_1 = doctor.n_total - doctor_n_2;% 常规病人区医生数量
    expert_n_1 = expert.n_total - expert_n_2;% 常规病人区专家数量
    check_n_1 = check.n_total - check_n_2;% 常规病人区检查设备数量
    
    [DR1 , AS1] = medical_distribution(PN1 , k1, nurse_n_1, doctor_n_1, expert_n_1, check_n_1);% 常规病人
    [DR2 , AS2] = medical_distribution(PN2 , k2, nurse_n_2, doctor_n_2, expert_n_2, check_n_2);% 突发病人
    DR(scheme_i) = (DR1*PN1 + DR2*PN2)/(PN1 + PN2);% 死亡率
    AS(scheme_i) = (AS1*PN1 + AS2*PN2)/(PN1 + PN2);% 平均系统逗留时间
end
DR_std = mean(DR);
AS_std = mean(AS);
f_method_2 = tao1 * (DR - DR_std)/DR_std + tao2 * (AS - AS_std)/AS_std;% 原文评价指标

% 方案3：sqrt((PN1/PN2)*(k1/k2))
DR = zeros(scheme_length,1);
AS = zeros(scheme_length,1);
for scheme_i = 1:scheme_length
    PN1 = scheme(scheme_i,1);% 常规病人数量
    PN2 = scheme(scheme_i,2);% 突发病人数量
    k1 = scheme(scheme_i,3);% 常规病人恶化率系数
    k2 = scheme(scheme_i,4);% 突发病人恶化率系数
    
    method_3 = sqrt((PN1/PN2)*(k1/k2));
    
    nurse_n_2 = round(nurse.n_total/(method_3 + 1));% 突发病人区护士数量
    doctor_n_2 = round(doctor.n_total/(method_3 + 1));
    expert_n_2 = round(expert.n_total/(method_3 + 1));
    check_n_2 = round(check.n_total/(method_3 + 1));
    nurse_n_1 = nurse.n_total - nurse_n_2;% 常规病人区护士数量
    doctor_n_1 = doctor.n_total - doctor_n_2;% 常规病人区医生数量
    expert_n_1 = expert.n_total - expert_n_2;% 常规病人区专家数量
    check_n_1 = check.n_total - check_n_2;% 常规病人区检查设备数量
    
    [DR1 , AS1] = medical_distribution(PN1 , k1, nurse_n_1, doctor_n_1, expert_n_1, check_n_1);% 常规病人
    [DR2 , AS2] = medical_distribution(PN2 , k2, nurse_n_2, doctor_n_2, expert_n_2, check_n_2);% 突发病人
    DR(scheme_i) = (DR1*PN1 + DR2*PN2)/(PN1 + PN2);% 死亡率
    AS(scheme_i) = (AS1*PN1 + AS2*PN2)/(PN1 + PN2);% 平均系统逗留时间
end
DR_std = mean(DR);
AS_std = mean(AS);
f_method_3 = tao1 * (DR - DR_std)/DR_std + tao2 * (AS - AS_std)/AS_std;% 原文评价指标

plot(1:scheme_length,f_method_1-0.1,'LineWidth',2);hold on
plot(1:scheme_length,f_method_2,':','LineWidth',2);hold on
plot(1:scheme_length,f_method_3+0.1,'--','LineWidth',2);
legend('第1种资源配置规则','第2种资源配置规则','第3种资源配置规则')
xlabel('系统场景','Fontsize',12);
ylabel('综合评价指标','Fontsize',12);
title('不同场景下3类资源配置规则的系统性能','Fontsize',15)