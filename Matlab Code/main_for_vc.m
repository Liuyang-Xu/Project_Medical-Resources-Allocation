clear,clc;
% validity check
% 终止型序贯程序法

% 输入参数
PN1 = 50;% 常规病人数量
PN2 = 50;% 突发病人数量
k1 = 0.4;% 常规病人恶化率系数
k2 = 0.8;% 突发病人恶化率系数

DR1_history = [];
AS1_history = [];

loop_max = 50;
for loop = 1:loop_max  
    % 医疗资源
    nurse.n_total = 9;
    doctor.n_total = 12;
    expert.n_total = 8;
    check.n_total = 4;
    % 可根据比例调节具体数值
    nurse.n = 5;
    doctor.n = 6;
    expert.n = 4;
    check.n = 2;
    
    % 阈值参数
    SI = 1.1;% 护士诊断
    Cd = 0.85;% 医生诊断信心
    Ce = 0.71;% 专家诊断信心
    
    epsilon = 0.0001;% 代替恒等判断的极小值
    
    % 初始化病人到达时间间隔AI(arrival interval)
    lamda = 0.5;% 病人平均到达率 = 人/tick
    AI = exprnd(1/lamda, PN1-1, 1);% 相邻病人的到达时间间隔服从1/lamda的指数分布(N个人有N-1个间隔)
    AI = roundn(AI,-1);
    AI(AI <= 0) = 0.1;% 相邻病人的最小时间间隔为0.1tick
    
    % 初始化病人到达时刻
    patient.arrival = zeros(PN1,1);
    for i = 1 : PN1-1
        patient.arrival(i+1) = sum(AI(1:i));
    end
    
    % 初始化病人状态
    patient.status = zeros(PN1,1);% 病人所处状态[0:未进入就诊;1:正在就诊;2:结束就诊]
    patient.H0 = random('uniform',0.5,1,PN1,1);% 病人初始生理状态
    sigma_0 = 0.01*betarnd(2,2,PN1,1);% 服从分布~0.01*BETA(2,2)
    sigma_1 = k1*sigma_0;% 常规病人恶化率
    sigma_2 = k2*sigma_0;% 突发病人恶化率
    patient.exit = zeros(PN1,1);% 病人完成就诊时刻
    patient.ifcheck = zeros(PN1,1);% 病人是否进行过检查，0为否，1为是
    patient.ifdead = zeros(PN1,1);
    patient.dOe = zeros(PN1,1);% 病人之前被医生还是专家检查，1为医生，2为专家；以便检查后重新排队
    
    % 初始化护士服务时间
    miu_n = 2.4;% 护士服务时间均值
    sigma_n = sqrt(1.29);% 护士服务时间标准差
    ST_n = normrnd(miu_n, sigma_n, PN1,1);
    ST_n = roundn(ST_n,-1);
    ST_n(ST_n <= 0) = 0.1;
    
    % 初始化医生服务时间
    miu_d = 10.7;% 医生服务时间均值
    sigma_d = sqrt(15.11);% 医生服务时间标准差
    ST_d = normrnd(miu_d, sigma_d, PN1,1);
    ST_d = roundn(ST_d,-1);
    ST_d(ST_d <= 0) = 0.1;
    
    % 初始化专家服务时间
    miu_e = 15;% 专家服务时间均值
    sigma_e = sqrt(22.54);% 专家服务时间标准差
    ST_e = normrnd(miu_e, sigma_e, PN1,1);
    ST_e = roundn(ST_e,-1);
    ST_e(ST_e <= 0) = 0.1;
    
    % 初始化辅助检查时间
    miu_c = 8.3;% 辅助检查时间均值
    sigma_c = sqrt(12.30);% 辅助检查时间标准差
    ST_c = normrnd(miu_c, sigma_c, PN1,1);
    ST_c = roundn(ST_c,-1);
    ST_c(ST_c <= 0) = 0.1;
    
    % 初始化队列
    nurse.queue = [];% 初始化分诊台等候队列
    nurse.dead_queue = [];% 初始化分诊台死亡队列
    nurse.service = zeros(nurse.n,2);
    % 初始化分诊台护士服务队列。
    % 0表示未在服务，可引入等候队列首位；非0数字表示正在服务的病人序号。
    % 第2列用于记录开始服务的时刻。
    nurse.dead_service =[];% 初始化分诊台护士服务死亡队列
    doctor.queue = [];% 初始化医生等候队列
    doctor.dead_queue = [];
    doctor.service = zeros(doctor.n,2);% 初始化医生服务队列
    doctor.dead_service = [];
    expert.queue = [];% 初始化专家等候队列
    expert.dead_queue = [];
    expert.service = zeros(expert.n,2);% 初始化专家服务队列
    expert.dead_service = [];
    check.queue = [];% 初始化辅助检查等候队列
    check.dead_queue =[];
    check.service = zeros(check.n,2);% 初始化辅助检查服务队列
    check.dead_service = [];
    
    % 就医流程
    T = 0;% 初始时刻
    T_delta = 0.1;% 最小时刻步长
    new_arrival = 1;% 初始化病人开始参与就诊流程
    while sum(patient.status) < 2*PN1% 循环至所有病人均结束就诊流程
        % 检查病人死亡情况，如有死亡则该病人结束就诊
        patient_real = find(patient.status == 1);
        RH = calculate_RH(patient_real,patient,sigma_1,T);% 计算T时刻下病人健康状况
        if ~isempty(patient_real)
            patient_dead = patient_real(abs(RH - 0) < epsilon);% 记录下健康状况为0，即死亡的病人
            patient.status(patient_dead) = 2;% 将死亡病人的状态变更为结束就诊
            patient.ifdead(patient_dead) = 1;% 将死亡病人的ifdead状态变更为1
            patient.exit(patient_dead) = T;% 记录死亡病人的死亡时刻
            patient_alive = setdiff(patient_real,patient_dead);% 将patient_real中的死亡病人去除，记为patient_alive;
            RH(abs(RH - 0) < epsilon) = [];% 清除健康状况矩阵中死亡数据，此时patient_alive与RH数据重新对应
            
            % 将死亡的病人加入对应的死亡队列
            nurse.dead_queue = [nurse.dead_queue;intersect(patient_dead,nurse.queue)];% 记录分诊台等候队列中死亡的病人
            nurse.dead_service = [nurse.dead_service;intersect(patient_dead,nurse.service)];% 记录分诊台护士服务队列中死亡的病人
            doctor.dead_queue = [doctor.dead_queue;intersect(patient_dead,doctor.queue)];
            doctor.dead_service = [doctor.dead_service;intersect(patient_dead,doctor.service)];
            expert.dead_queue = [expert.dead_queue;intersect(patient_dead,expert.queue)];
            expert.dead_service = [expert.dead_service;intersect(patient_dead,expert.service)];
            check.dead_queue = [check.dead_queue;intersect(patient_dead,check.queue)];
            check.dead_service = [check.dead_service;intersect(patient_dead,check.service)];
            % 将原各等待与服务队列去除死亡的病人
            nurse.queue = setdiff(nurse.queue,patient_dead);% setdiff(A,B)为删掉A中B出现的相同的元素
            dead_member_nurse= ismember(nurse.service(:,1), patient_dead);
            nurse.service(dead_member_nurse ==1,:) = 0;% 将死亡的病人在service队列中归0
            doctor.queue = setdiff(doctor.queue,patient_dead);
            dead_member_doctor = ismember(doctor.service(:,1), patient_dead);
            doctor.service(dead_member_doctor ==1,:) = 0;% 将死亡的病人在service队列中归0
            expert.queue = setdiff(expert.queue,patient_dead);
            dead_member_expert = ismember(expert.service(:,1), patient_dead);
            expert.service(dead_member_expert ==1,:) = 0;% 将死亡的病人在service队列中归0
            check.queue = setdiff(check.queue,patient_dead);
            dead_member_check = ismember(check.service(:,1), patient_dead);
            check.service(dead_member_check ==1,:) = 0;% 将死亡的病人在service队列中归0
            fprintf('已记录并清除死亡病人\n');
        end
        
        % 如有新到来的病人，将其加进分诊台等候队列
        if abs(patient.arrival(new_arrival) - T) < epsilon
            nurse.queue(end+1) = new_arrival;
            patient.status(new_arrival) = 1;% 该病人的状态变更为正在就诊
            if new_arrival < PN1
                new_arrival = new_arrival +1;
            end
            fprintf('已将新的病人加入分诊台等候队列\n');
        end
        
        % 将分诊台等候队列中的病人分配至护士处就诊
        for nurse_n = 1:nurse.n
            if nurse.service(nurse_n,1) == 0% 当该护士没有诊断病人时
                if ~isempty(nurse.queue)% 若分诊台等待队列非空
                    nurse.service(nurse_n,1) = nurse.queue(1);% 分配给该护士等待队列里的第一个病人
                    nurse.service(nurse_n,2) = T;% 记录服务开始时刻
                    nurse.queue(1) = [];% 删除等待队列里的这名病人
                end
            else % 该护士正在诊断病人
                if abs(T - (nurse.service(nurse_n,2) + ST_n(nurse.service(nurse_n,1)))) < epsilon
                    fprintf('护士已完成服务\n');
                    nurse_SI = calculate_SI(RH(patient_alive == nurse.service(nurse_n,1)));% 计算诊断信心
                    if nurse_SI < SI% nurse_SI小于SI时，病人被分流至医师处
                        doctor.queue(end+1) = nurse.service(nurse_n,1);% 将护士服务完的该病人移至医生等待队列
                        nurse.service(nurse_n,:) = 0;% 将该护士服务信息清0
                    else
                        expert.queue(end+1) = nurse.service(nurse_n,1);% 将护士服务完的该病人移至专家等待队列
                        nurse.service(nurse_n,:) = 0;% 将该护士服务信息清0
                    end
                end
            end
        end
        
        % 将医生等待队列中的病人分配至医生就诊处就诊
        for doctor_n = 1:doctor.n
            if doctor.service(doctor_n,1) == 0% 当该医生没有诊断病人时
                if ~isempty(doctor.queue)% 若医生等待队列非空
                    doctor.service(doctor_n,1) = doctor.queue(1);% 分配给该医生等待队列里的第一个病人
                    doctor.service(doctor_n,2) = T;% 记录服务开始时刻
                    doctor.queue(1) = [];% 删除等待队列里的这名病人
                end
            else % 该医生正在诊断病人
                if abs(T - (doctor.service(doctor_n,2) + ST_d(doctor.service(doctor_n,1)))) < epsilon% 若已达就诊时长，则结束就诊
                    fprintf('医生已完成服务\n');
                    doctor_Cd = calculate_Cd(RH(patient_alive == doctor.service(doctor_n,1)));% 计算诊断信心
                    if doctor_Cd < Cd% doctor_Cd小于Cd时
                        if patient.ifcheck(doctor.service(doctor_n,1)) == 0%且病人未做检查时
                            check.queue(end+1) = doctor.service(doctor_n,1);% 将医生服务完的该病人移至辅助检查等待队列
                            patient.dOe(doctor.service(doctor_n,1)) = 1;% 标记该病人之前被医生检查过
                            doctor.service(doctor_n,:) = 0;% 将该医生服务信息清0
                        else% 否则将该病人分流至专家等待队列
                            expert.queue(end+1) = doctor.service(doctor_n,1);% 将医生服务完的该病人移至专家等待队列
                            doctor.service(doctor_n,:) = 0;% 将该医生服务信息清0
                        end
                    else
                        patient.status(doctor.service(doctor_n,1)) = 2;% 更改病人状态为结束就诊
                        patient.exit(doctor.service(doctor_n,1)) = T;% 记录病人结束就诊时刻
                        doctor.service(doctor_n,:) = 0;% 将该医生服务信息清0
                    end
                end
            end
        end
        
        % 将专家等待队列中的病人分配至专家就诊处就诊
        for expert_n = 1:expert.n
            if expert.service(expert_n,1) == 0% 当该专家没有诊断病人时
                if ~isempty(expert.queue)% 若专家等待队列非空
                    expert.service(expert_n,1) = expert.queue(1);% 分配给该专家等待队列里的第一个病人
                    expert.service(expert_n,2) = T;% 记录服务开始时刻
                    expert.queue(1) = [];% 删除等待队列里的这名病人
                end
            else % 该专家正在诊断病人
                if abs(T - (expert.service(expert_n,2) + ST_e(expert.service(expert_n,1)))) < epsilon% 若已达就诊时长，则结束就诊
                    fprintf('专家已完成服务\n');
                    expert_Ce = calculate_Cd(RH(patient_alive == expert.service(expert_n,1)));% 计算诊断信心
                    if expert_Ce < Ce% expert_Ce小于Ce时
                        if patient.ifcheck(expert.service(expert_n,1)) == 0%且病人未做检查时
                            check.queue(end+1) = expert.service(expert_n,1);% 将专家服务完的该病人移至辅助检查等待队列
                            patient.dOe(expert.service(expert_n,1)) = 2;% 标记该病人 之前被专家检查过
                            expert.service(expert_n,:) = 0;% 将该专家服务信息清0
                        else
                            patient.status(expert.service(expert_n,1)) = 2;% 更改病人状态为结束就诊
                            patient.exit(expert.service(expert_n,1)) = T;% 记录病人结束就诊时刻
                            expert.service(expert_n,:) = 0;% 将该专家服务信息清0
                        end
                    else
                        patient.status(expert.service(expert_n,1)) = 2;% 更改病人状态为结束就诊
                        patient.exit(expert.service(expert_n,1)) = T;% 记录病人结束就诊时刻
                        expert.service(expert_n,:) = 0;% 将该专家服务信息清0
                    end
                end
            end
        end
        
        % 将辅助检查等待队列中的病人分配至辅助检查处进行检查
        for check_n = 1:check.n
            if check.service(check_n,1) == 0% 当该设备没有检查病人时
                if ~isempty(check.queue)% 若辅助检查等待队列非空
                    check.service(check_n,1) = check.queue(1);% 分配给该设备等待队列里的第一个病人
                    check.service(check_n,2) = T;% 记录检查开始时刻
                    check.queue(1) = [];% 删除等待队列里的这名病人
                end
            else % 该设备正在诊断病人
                if abs(T - (check.service(check_n,2) + ST_c(check.service(check_n,1)))) < epsilon% 若已达检查时长，则结束检查
                    % 检查完后要更改ifcheck状态为1，并根据dOe回归原队列
                    fprintf('设备已完成检查\n');
                    if patient.dOe(check.service(check_n,1)) == 1% 标记该病人 之前被医生检查过
                        patient.ifcheck(check.service(check_n,1)) = 1;% 标记该病人已做过设备检查
                        doctor.queue(end+1) = check.service(check_n,1);% 将检查完的该病人移至医生等待队列
                        check.service(check_n,:) = 0;% 将该设备检查信息清0
                    elseif patient.dOe(check.service(check_n,1)) == 2% 标记该病人 之前被专家检查过
                        patient.ifcheck(check.service(check_n,1)) = 1;% 标记该病人已做过设备检查
                        expert.queue(end+1) = check.service(check_n,1);% 将检查完的该病人移至专家等待队列
                        check.service(check_n,:) = 0;% 将该设备检查信息清0
                    end
                end
            end
        end
        
        T = T + T_delta
    end
    
    ZD = sum(patient.ifdead);% 死亡人数
    ZP = PN1 - ZD;% 完成就诊的病人数
    DR1 = ZD / PN1;% 死亡率
    
    ZS_a = patient.exit - patient.arrival;% 所有病人的系统逗留时间
    ZS = ZS_a.* (1-patient.ifdead);% 增加的系统逗留时间
    S = sum(ZS);% 总的系统逗留时间
    AS1 = S / PN1;% 平均系统逗留时间
    
    DR1_history(end+1) = DR1;
    AS1_history(end+1) = AS1;
end

DR1_history = DR1_history';
AS1_history = AS1_history';

% 值置信度为 90% ，置信区间半宽小于点估计的 20%
ifpass_DR1 = calculate_confidence(DR1_history,90,1);% 1表示是，0表示否
ifpass_AS1 = calculate_confidence(AS1_history,90,1);