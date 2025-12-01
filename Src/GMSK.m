%% GMSK调制解调系统完整仿真
clear; clc; close all;

%% 参数设置
N_bits = 20;                    % 比特数
Tb = 1;                         % 码元周期
dt = 0.01;                      % 采样间隔
t = 0:dt:N_bits*Tb-dt;          % 时间轴
E = 1;                          % 信号能量
fc = 5;                         % 载波频率 (Hz)

%% 生成随机比特序列
original_bits = [1, -1, -1, -1, 1, 1, 1, -1, 1, -1, -1, 1, 1, -1, 1, -1, 1, 1, -1, -1];
% original_bits = 2*randi([0 1], 1, N_bits) - 1; % 随机生成±1序列

fprintf('原始比特序列: ');
disp(original_bits);

%% GMSK调制过程
fprintf('\n=== GMSK调制过程 ===\n');

% 高斯脉冲成形函数
gt = @(t) (erfc(2*pi*0.3*(t - 2) / sqrt(2*log(2))) - erfc(2*pi*0.3*(t + 1) / sqrt(2*log(2)))) / 2;

% 初始化相位和信号
theta = [0, 1, 1];  % 初始相位状态
modulated_I = [];   % 同相分量
modulated_Q = [];   % 正交分量
phase_history = []; % 相位历史
time_history = [];  % 时间历史
gmsk_signal = [];   % GMSK调制信号
gmsk_transmit = []; % 发送端GMSK信号（带载波）

% 调制每个比特 - 高采样率用于显示连续波形
for n = 1:N_bits
    % 计算当前比特的相位贡献
    current_bit = original_bits(n);
    
    % 更新相位状态
    next_theta = [theta(1) + theta(2) * pi/2, theta(3), current_bit];
    
    % 生成高采样率的调制信号用于显示连续波形
    [Sn_high, Cn_high, phase_high, t_high, gmsk_high, gmsk_transmit_high] = ...
        gmsk_modulate_high_res([next_theta, theta], n-1, gt, Tb, dt, E, fc);
    
    % 生成用于解调的4点采样信号
    [Sn, Cn, phase] = gmsk_modulate([next_theta, theta], n-1, gt);
    
    % 添加噪声到解调信号
    Sn_noisy = Sn + 0.5*randn(1,4);
    Cn_noisy = Cn + 0.5*randn(1,4);
    
    % 存储信号
    modulated_I = [modulated_I, Sn_noisy];
    modulated_Q = [modulated_Q, Cn_noisy];
    phase_history = [phase_history, phase_high];
    time_history = [time_history, t_high + (n-1)*Tb];
    gmsk_signal = [gmsk_signal, gmsk_high];
    gmsk_transmit = [gmsk_transmit, gmsk_transmit_high];
    
    % 更新相位状态
    theta = next_theta;
end

%% 绘制发送端GMSK调制波形 - 专门窗口
figure('Position', [50, 50, 1400, 1000]);
sgtitle('发送端GMSK调制信号波形', 'FontSize', 16, 'FontWeight', 'bold');

% 1. 原始比特序列
subplot(3,3,1);
bit_time = 0:N_bits-1;
stem(bit_time, original_bits, 'filled', 'b', 'LineWidth', 2);
title('原始比特序列');
xlabel('比特索引');
ylabel('比特值');
grid on;
ylim([-1.5, 1.5]);

% 2. 连续相位轨迹
subplot(3,3,2);
plot(time_history, phase_history, 'g-', 'LineWidth', 2);
hold on;
% 标记每个比特开始的位置
for n = 1:N_bits
    plot([(n-1)*Tb, (n-1)*Tb], [min(phase_history)-0.5, max(phase_history)+0.5], 'r--', 'LineWidth', 0.5);
end
title('GMSK连续相位轨迹');
xlabel('时间 (s)');
ylabel('相位 (弧度)');
grid on;
xlim([0, N_bits*Tb]);

% 3. GMSK基带信号 - 实部
subplot(3,3,3);
plot(time_history, real(gmsk_signal), 'm-', 'LineWidth', 1.5);
title('GMSK基带信号 - 实部');
xlabel('时间 (s)');
ylabel('幅度');
grid on;
xlim([0, N_bits*Tb]);

% 4. GMSK基带信号 - 虚部
subplot(3,3,4);
plot(time_history, imag(gmsk_signal), 'c-', 'LineWidth', 1.5);
title('GMSK基带信号 - 虚部');
xlabel('时间 (s)');
ylabel('幅度');
grid on;
xlim([0, N_bits*Tb]);

% 5. 发送端GMSK信号 - 完整波形
subplot(3,3,5);
plot(time_history, gmsk_transmit, 'b-', 'LineWidth', 1.5);
title('发送端GMSK调制信号 (带载波)');
xlabel('时间 (s)');
ylabel('幅度');
grid on;
xlim([0, N_bits*Tb]);

% 6. 发送端GMSK信号 - 前3个码元细节
subplot(3,3,6);
end_idx = min(length(time_history), round(3*Tb/dt));
plot(time_history(1:end_idx), gmsk_transmit(1:end_idx), 'b-', 'LineWidth', 1.5);
hold on;
% 叠加载波参考
carrier_ref = cos(2*pi*fc*time_history(1:end_idx));
plot(time_history(1:end_idx), 0.5*carrier_ref, 'r--', 'LineWidth', 1);
title('前3个码元GMSK信号细节');
xlabel('时间 (s)');
ylabel('幅度');
legend('GMSK信号', '载波参考', 'Location', 'best');
grid on;

% 7. GMSK信号包络
subplot(3,3,7);
envelope = abs(gmsk_signal);
plot(time_history, envelope, 'k-', 'LineWidth', 2);
title('GMSK信号包络 (恒定包络特性)');
xlabel('时间 (s)');
ylabel('幅度');
grid on;
xlim([0, N_bits*Tb]);
ylim([0, 2]);

% 8. 瞬时频率变化
subplot(3,3,8);
% 计算瞬时频率 (相位差分)
instant_phase = unwrap(phase_history);
instant_freq = diff(instant_phase) / (2*pi*dt);
plot(time_history(1:end-1), instant_freq, 'r-', 'LineWidth', 1.5);
hold on;
% 标记理论频偏
plot([0, N_bits*Tb], [fc, fc], 'k--', 'LineWidth', 1);
plot([0, N_bits*Tb], [fc+0.25/Tb, fc+0.25/Tb], 'g--', 'LineWidth', 1);
plot([0, N_bits*Tb], [fc-0.25/Tb, fc-0.25/Tb], 'g--', 'LineWidth', 1);
title('GMSK瞬时频率');
xlabel('时间 (s)');
ylabel('频率 (Hz)');
legend('瞬时频率', '载波频率', '最大频偏', 'Location', 'best');
grid on;
xlim([0, N_bits*Tb]);

% 9. 频谱分析
subplot(3,3,9);
[Pxx, F] = pwelch(gmsk_transmit, [], [], [], 1/dt);
semilogy(F, Pxx, 'b-', 'LineWidth', 1.5);
hold on;
% 标记载波频率
plot([fc, fc], [min(Pxx), max(Pxx)], 'r--', 'LineWidth', 1);
title('GMSK信号功率谱密度');
xlabel('频率 (Hz)');
ylabel('功率谱密度');
legend('GMSK频谱', '载波频率', 'Location', 'best');
grid on;
xlim([0, 2*fc]);

%% 绘制调制过程波形 - 单独窗口
figure('Position', [200, 200, 1400, 1000]);
sgtitle('GMSK调制过程详细显示', 'FontSize', 16, 'FontWeight', 'bold');

% 1. 原始比特序列
subplot(3,2,1);
stem(0:N_bits-1, original_bits, 'filled', 'LineWidth', 2);
title('原始比特序列');
xlabel('比特索引');
ylabel('比特值');
grid on;
ylim([-1.5, 1.5]);

% 2. 连续相位轨迹
subplot(3,2,2);
plot(time_history, phase_history, 'g-', 'LineWidth', 2);
hold on;
% 标记每个比特开始的位置
for n = 1:N_bits
    plot([(n-1)*Tb, (n-1)*Tb], [min(phase_history)-0.5, max(phase_history)+0.5], 'r--', 'LineWidth', 0.5);
end
title('GMSK连续相位轨迹');
xlabel('时间 (s)');
ylabel('相位 (弧度)');
grid on;
xlim([0, N_bits*Tb]);

% 3. 同相分量 (I)
subplot(3,2,3);
plot(time_history, sqrt(2*E/Tb)*cos(phase_history), 'b-', 'LineWidth', 1.5);
title('GMSK同相分量 I(t)');
xlabel('时间 (s)');
ylabel('幅度');
grid on;
xlim([0, N_bits*Tb]);

% 4. 正交分量 (Q)
subplot(3,2,4);
plot(time_history, sqrt(2*E/Tb)*sin(phase_history), 'r-', 'LineWidth', 1.5);
title('GMSK正交分量 Q(t)');
xlabel('时间 (s)');
ylabel('幅度');
grid on;
xlim([0, N_bits*Tb]);

% 5. 发送端GMSK信号
subplot(3,2,5);
plot(time_history, gmsk_transmit, 'b-', 'LineWidth', 1.5);
title('发送端GMSK调制信号');
xlabel('时间 (s)');
ylabel('幅度');
grid on;
xlim([0, N_bits*Tb]);

% 6. 星座图
subplot(3,2,6);
I_continuous = sqrt(2*E/Tb)*cos(phase_history);
Q_continuous = sqrt(2*E/Tb)*sin(phase_history);
scatter(I_continuous(1:10:end), Q_continuous(1:10:end), 10, 'filled', 'b');
hold on;
% 标记起点和终点
plot(I_continuous(1), Q_continuous(1), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
plot(I_continuous(end), Q_continuous(end), 'rx', 'MarkerSize', 8, 'LineWidth', 2);
title('GMSK连续星座图');
xlabel('同相分量 I');
ylabel('正交分量 Q');
grid on;
axis equal;

%% GMSK解调过程
fprintf('\n=== GMSK解调过程 ===\n');

% 状态转移表
TransferTable = [
    0 +1 +1 pi/2 +1 -1 pi -1 +1 pi/2 +1 +1 
    0 +1 +1 pi/2 +1 -1 pi -1 +1 pi/2 +1 -1  
    0 +1 +1 pi/2 +1 -1 pi -1 -1 pi/2 -1 +1 
    0 +1 +1 pi/2 +1 -1 pi -1 -1 pi/2 -1 -1  
    0 +1 +1 pi/2 +1 +1 pi +1 +1 -pi/2 +1 +1
    0 +1 +1 pi/2 +1 +1 pi +1 +1 -pi/2 +1 -1
    0 +1 +1 pi/2 +1 +1 pi +1 -1 -pi/2 -1 +1   
    0 +1 +1 pi/2 +1 +1 pi +1 -1 -pi/2 -1 -1 
];

% 解调路径表
TransferPath = [
   0        -1      +1     pi/2   -1      -1      -pi/2   +1      -1
   0        +1      +1      -pi/2    +1      +1      pi/2    -1     +1
   0        +1      -1      -pi/2    +1      +1      pi/2    -1      +1
   0        -1      -1     pi/2   -1      -1      -pi/2   +1      -1
   pi       -1      +1      pi/2    +1      -1      -pi/2    -1      -1
   pi       +1      +1      pi/2   +1      +1      -pi/2   -1     +1
   pi       +1      -1      pi/2   +1      +1      -pi/2   -1      +1
   pi       -1      -1      pi/2    +1      -1      -pi/2    -1      -1
   pi/2     -1      +1       pi       -1      -1      0       +1      -1
   pi/2     +1      +1      pi  -1      +1      0      +1      +1
   pi/2     +1      -1       0      +1      +1      pi      -1      +1
   pi/2     -1      -1       pi      -1      -1      0       +1      -1
   -pi/2    -1      +1      pi      +1      -1      0      -1      -1
   -pi/2    +1      +1      0       -1      +1      pi       +1     +1
   -pi/2    +1      -1      0       -1      +1      pi       +1      +1
   -pi/2    -1      -1      0     -1      -1      pi      +1      -1
];

% 维特比解码初始化
theta_now = [0, 1, 1];
hamming_head = zeros(8,3);
path = [];
hamming = [];
method = 'a';

% 解调每个比特
for i = 1:N_bits
    % 提取当前比特的接收信号
    start_idx = (i-1)*4 + 1;
    end_idx = i*4;
    Sn_current = modulated_I(start_idx:end_idx);
    Cn_current = modulated_Q(start_idx:end_idx);
    
    % 维特比解码
    [path_temp, hamming_temp1, hamming_temp2] = viterbi_decode(Sn_current, Cn_current, i-1, method, TransferTable, TransferPath, gt);
    
    % 路径度量处理
    if i == 4
        % 调整前3码元的路径度量
        hamming_head(5:8,1) = hamming_head(2,1);
        hamming_head(1:4,1) = hamming_head(1,1);
        hamming_head(7:8,2) = hamming_head(4,2);
        hamming_head(5:6,2) = hamming_head(3,2);
        hamming_head(3:4,2) = hamming_head(2,2);
        hamming_head(1:2,2) = hamming_head(1,2);
        
        hamming = zeros(8,1);
        for k = 1:8
            hamming(k,1) = sum(hamming_head(k,:));
        end
    end
    
    if i-1 > 3
        if isempty(hamming)
            hamming = hamming_temp1;
        else
            hamming = [hamming, hamming_temp1];
        end
    end
    
    hamming_head = hamming_head + hamming_temp2;
    
    % 修复路径存储问题
    if ~isempty(path_temp)
        if isempty(path)
            path = path_temp;
        else
            path = [path, path_temp];
        end
    end
    
    % 切换方法
    if i-1 > 3
        if method == 'a'
            method = 'b';
        else
            method = 'a';
        end
    end
end

%% 修复路径回溯部分
fprintf('\n=== 最终解码 ===\n');

% 检查路径矩阵维度
if isempty(path)
    error('路径矩阵为空，无法进行解码');
end

% 路径回溯 - 修复维度问题
num_segments = size(path, 2) / 6;
if num_segments ~= round(num_segments)
    error('路径矩阵列数不是6的倍数');
end

realpath = [];
new_hamming = [];

for i = 1:8
    tempth = path(i, 1:6);
    temp = path(i, 4:6);
    
    if size(hamming, 2) >= 2
        new_hamming_temp = hamming(i, 2);
    else
        new_hamming_temp = 0;
    end
    
    for k = 1:num_segments - 1
        start_col = 1 + k*6;
        end_col = 6 + k*6;
        
        if end_col > size(path, 2)
            break;
        end
        
        std_segment = path(:, start_col:end_col);
        found = false;
        
        for index = 1:8
            if index <= size(std_segment, 1) && all(temp == std_segment(index, 1:3))
                tempth = [tempth, std_segment(index, 4:6)]; %#ok<AGROW>
                if size(hamming, 2) >= k + 2
                    new_hamming_temp = [new_hamming_temp, hamming(index, k + 2)]; %#ok<AGROW>
                end
                temp = std_segment(index, 4:6);
                found = true;
                break;
            end
        end
        
        if ~found && ~isempty(std_segment)
            % 如果没有找到匹配，使用第一个路径
            tempth = [tempth, std_segment(1, 4:6)]; %#ok<AGROW>
            if size(hamming, 2) >= k + 2
                new_hamming_temp = [new_hamming_temp, hamming(1, k + 2)]; %#ok<AGROW>
            end
            temp = std_segment(1, 4:6);
        end
    end
    
    realpath = [realpath; tempth]; %#ok<AGROW>
    new_hamming = [new_hamming; new_hamming_temp]; %#ok<AGROW>
end

% 最终路径排序
realpath2 = [];
new_hamming2 = [];

for i = 1:8
    temph = TransferTable(i, 10:12);
    for k = 1:size(realpath, 1)
        if k <= size(realpath, 1) && all(temph == realpath(k, 1:3))
            realpath2 = [realpath2; realpath(k, :)]; %#ok<AGROW>
            new_hamming2 = [new_hamming2; new_hamming(k, :)]; %#ok<AGROW>
            break;
        end
    end
end

% 计算最终路径度量
if isempty(hamming)
    finalhamming = sum(hamming_head, 2);
else
    finalhamming = [hamming(:,1), hamming_head, new_hamming2];
    for i = 1:min(8, size(finalhamming, 1))
        finalhamming(i,1) = sum(finalhamming(i,2:end));
    end
end

% 选择最佳路径
if ~isempty(finalhamming)
    [~, best_path_idx] = max(finalhamming(:,1));
    decoded_path = [TransferTable(:,1:9), realpath2];
    
    % 提取解码比特
    decoded_bits = [];
    for i = 6:3:min(size(decoded_path, 2), 3*N_bits+3)
        if i <= size(decoded_path, 2)
            decoded_bits = [decoded_bits, decoded_path(best_path_idx, i)]; %#ok<AGROW>
        end
    end
    
    fprintf('解码比特序列: ');
    disp(decoded_bits);
    fprintf('最佳路径号: %d\n', best_path_idx);
    
    % 计算误码率
    compare_length = min(length(original_bits), length(decoded_bits));
    bit_errors = sum(original_bits(1:compare_length) ~= decoded_bits(1:compare_length));
    ber = bit_errors / compare_length;
    
    fprintf('误比特数: %d\n', bit_errors);
    fprintf('误码率: %.4f\n', ber);
else
    decoded_bits = [];
    bit_errors = N_bits;
    ber = 1;
    fprintf('解码失败\n');
end

%% 绘制解调结果
figure('Position', [100, 100, 1200, 800]);

% 原始比特序列
subplot(3,2,1);
stem(0:N_bits-1, original_bits, 'filled', 'LineWidth', 2);
title('原始比特序列');
xlabel('比特索引');
ylabel('比特值');
grid on;
ylim([-1.5, 1.5]);

% 解码比特序列
subplot(3,2,2);
if ~isempty(decoded_bits)
    stem(0:length(decoded_bits)-1, decoded_bits, 'filled', 'r', 'LineWidth', 2);
end
title('解码比特序列');
xlabel('比特索引');
ylabel('比特值');
grid on;
ylim([-1.5, 1.5]);

% 路径度量
subplot(3,2,3);
if ~isempty(finalhamming)
    bar(finalhamming(:,1));
end
title('最终路径度量值');
xlabel('路径索引');
ylabel('度量值');
grid on;

% 星座图
subplot(3,2,4);
scatter(modulated_I, modulated_Q, 20, 'filled');
title('接收信号星座图（含噪声）');
xlabel('同相分量');
ylabel('正交分量');
grid on;
axis equal;

% 误码比较
subplot(3,2,5);
if ~isempty(decoded_bits)
    compare_length = min(length(original_bits), length(decoded_bits));
    error_pattern = original_bits(1:compare_length) ~= decoded_bits(1:compare_length);
    stem(0:compare_length-1, error_pattern, 'filled', 'm', 'LineWidth', 2);
end
title('误码位置 (红色表示错误)');
xlabel('比特索引');
ylabel('错误标志');
grid on;
ylim([-0.5, 1.5]);

% 系统性能总结
subplot(3,2,6);
text(0.1, 0.8, sprintf('总比特数: %d', N_bits), 'FontSize', 12);
if ~isempty(decoded_bits)
    text(0.1, 0.6, sprintf('正确解码: %d', N_bits - bit_errors), 'FontSize', 12);
    %text(0.1, 0.4, sprintf('误比特数: %d', bit_errors), 'FontSize', 12);
    %text(0.1, 0.2, sprintf('误码率: %.2f%%', ber * 100), 'FontSize', 12);
else
    text(0.1, 0.6, '解码失败', 'FontSize', 12, 'Color', 'red');
end
axis off;
title('系统性能总结');

sgtitle('GMSK解调结果', 'FontSize', 14, 'FontWeight', 'bold');

%% 显示系统性能
fprintf('\n=== 系统性能总结 ===\n');
fprintf('总比特数: %d\n', N_bits);
if ~isempty(decoded_bits)
    fprintf('正确解码比特数: %d\n', N_bits - bit_errors);
    fprintf('误码率: %.2f%%\n', ber * 100);
else
    fprintf('解码失败\n');
end

%% GMSK调制函数 - 用于解调（4点采样）
function [Sn, Cn, phase] = gmsk_modulate(TransferPath, n, gt)
    E = 1;
    Tb = 1;
    
    % 采样时间点
    t_points = [0.1*Tb, 0.3*Tb, 0.5*Tb, 0.8*Tb];
    tn_1 = t_points - (n - 1)*Tb;
    tn_2 = t_points - (n - 2)*Tb;
    tn   = t_points - n*Tb;
    
    % 计算高斯脉冲响应
    rtn_1 = arrayfun(@(x) integral(gt, -0.1, x) / (2*Tb), tn_1);
    rtn_2 = arrayfun(@(x) integral(gt, -0.1, x) / (2*Tb), tn_2);
    rtn   = arrayfun(@(x) integral(gt, -0.1, x) / (2*Tb), tn);
    
    % 计算相位
    rtn_1 = rtn_1 .* pi .* TransferPath(2);
    rtn_2 = rtn_2 .* pi .* TransferPath(5);
    rtn   = rtn   .* pi .* TransferPath(3);
    
    phase = rtn + rtn_1 + rtn_2 + TransferPath(1);
    
    % 生成I/Q信号
    Sn = sqrt(2*E/Tb) * cos(phase);
    Cn = sqrt(2*E/Tb) * sin(phase);
end

%% GMSK调制函数 - 高分辨率用于显示连续波形
function [Sn, Cn, phase, t, gmsk_signal, gmsk_transmit] = gmsk_modulate_high_res(TransferPath, n, gt, Tb, dt, E, fc)
    % 高分辨率时间点
    t = (n*Tb):dt:((n+1)*Tb - dt);
    
    % 计算高斯脉冲响应
    rtn_1 = arrayfun(@(x) integral(gt, -0.1, x - (n - 1)*Tb) / (2*Tb), t);
    rtn_2 = arrayfun(@(x) integral(gt, -0.1, x - (n - 2)*Tb) / (2*Tb), t);
    rtn   = arrayfun(@(x) integral(gt, -0.1, x - n*Tb) / (2*Tb), t);
    
    % 计算相位
    rtn_1 = rtn_1 .* pi .* TransferPath(2);
    rtn_2 = rtn_2 .* pi .* TransferPath(5);
    rtn   = rtn   .* pi .* TransferPath(3);
    
    phase = rtn + rtn_1 + rtn_2 + TransferPath(1);
    
    % 生成I/Q信号
    Sn = sqrt(2*E/Tb) * cos(phase);
    Cn = sqrt(2*E/Tb) * sin(phase);
    
    % 生成完整的GMSK基带信号 (复信号表示)
    gmsk_signal = Sn + 1i * Cn;
    
    % 生成发送端GMSK信号 (调制到载波)
    % GMSK信号: s(t) = cos(2πf_c t + φ(t))
    gmsk_transmit = cos(2*pi*fc*t + phase);
end

%% 维特比解码函数
function [path, hamming, hamming_head] = viterbi_decode(Sn, Cn, n, method, TransferTable, TransferPath, gt)
    path = [];
    temp_path = [];
    temp_hamming = [];
    hamming_head = zeros(8,3);
    hamming = [];
    
    % 前3个码元的处理
    if n <= 2
        index = 1;
        for i = 1:2^(n+1)
            if index <= size(TransferTable, 1)
                % 生成参考信号
                path_segment = [TransferTable(index,(1 + n*3 + 3):(6 + n*3)), TransferTable(index,(1 + n*3):(1 + n*3 + 2))];
                if length(path_segment) >= 6
                    [Sn1, Cn1] = gmsk_modulate(path_segment, n, gt);
                    
                    % 相关检测
                    result1 = dot(Sn1, Sn) + dot(Cn1, Cn);
                    hamming_head(i,n+1) = result1;
                end
                index = index + max(1, 2^(2 - n));
            end
        end
    else
        % 后续码元的处理
        switch method
            case 'a'
                indices = 1:8;
            case 'b'
                indices = 9:16;
            otherwise
                indices = 1:8;
        end
        
        for idx = indices
            if idx <= size(TransferPath, 1)
                % 第一条路径
                [Sn1, Cn1] = gmsk_modulate(TransferPath(idx,1:6), n, gt);
                
                % 第二条路径
                path2 = [TransferPath(idx,1:3), TransferPath(idx,7:9)];
                if length(path2) >= 6
                    [Sn2, Cn2] = gmsk_modulate(path2, n, gt);
                    
                    % 相关检测
                    result1 = dot(Sn1, Sn) + dot(Cn1, Cn);
                    result2 = dot(Sn2, Sn) + dot(Cn2, Cn);
                    
                    % 选择最佳路径
                    if result1 >= result2
                        temp_path = [temp_path; TransferPath(idx, 4:6), TransferPath(idx,1:3)];
                        temp_hamming = [temp_hamming; result1];
                    else
                        temp_path = [temp_path; TransferPath(idx, 7:9), TransferPath(idx,1:3)];
                        temp_hamming = [temp_hamming; result2];
                    end
                end
            end
        end
        
        if ~isempty(temp_path)
            path = temp_path;
            hamming = temp_hamming;
        end
    end
end
