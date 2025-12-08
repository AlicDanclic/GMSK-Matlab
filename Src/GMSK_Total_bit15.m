%% GMSK信号调制与解调完整仿真程序
% 作者：基于原始代码扩展
% 功能：生成任意长度的GMSK调制信号，显示完整调制过程，并进行Viterbi解码

clear; clc; close all;

%% 全局参数设置
bit_count = 20;          % 设置比特序列长度（可修改）
E = 1;                   % 信号能量
Tb = 1;                  % 码元长度
dt = 0.01;               % 时间分辨率
BT = 0.3;                % GMSK带宽时间积
fs = 100;                % 采样频率

%% 生成随机比特序列（-1和+1）
bit = 2 * randi([0, 1], 1, bit_count) - 1;
fprintf('生成的随机比特序列（长度=%d）：\n', bit_count);
disp(bit);

%% ================== 图1：发送端GMSK调制信号波形 ==================
figure('Position', [50, 50, 1400, 900], 'Name', '发送端GMSK调制信号波形');

% 子图1：原始比特序列
subplot(3, 3, 1);
stem(1:length(bit), bit, 'b', 'LineWidth', 1.5, 'Marker', 'o');
title('原始比特序列');
xlabel('比特序号'); ylabel('比特值');
grid on; xlim([0.5, length(bit)+0.5]);
ylim([-1.5, 1.5]);

% 生成完整的GMSK调制信号
[t, s_gmsk, I, Q, phase, freq, envelope, t_highres] = generate_full_gmsk_signal(bit, Tb, fs, BT);

% 子图2：GMSK连续相位轨迹
subplot(3, 3, 2);
plot(t_highres, phase, 'b', 'LineWidth', 1.5);
title('GMSK连续相位轨迹');
xlabel('时间 (s)'); ylabel('相位 (rad)');
grid on;

% 子图3：GMSK基带信号-实部(I)
subplot(3, 3, 3);
plot(t, I, 'b', 'LineWidth', 1.5);
title('GMSK基带信号-实部 I(t)');
xlabel('时间 (s)'); ylabel('幅度');
grid on;

% 子图4：GMSK基带信号-虚部(Q)
subplot(3, 3, 4);
plot(t, Q, 'r', 'LineWidth', 1.5);
title('GMSK基带信号-虚部 Q(t)');
xlabel('时间 (s)'); ylabel('幅度');
grid on;

% 子图5：发送端GMSK调制信号
subplot(3, 3, 5);
plot(t, s_gmsk, 'k', 'LineWidth', 1.5);
title('发送端GMSK调制信号');
xlabel('时间 (s)'); ylabel('幅度');
grid on;

% 子图6：前3个码元局部放大图
subplot(3, 3, 6);
t_start = 0;
t_end = 3*Tb;
idx = find(t >= t_start & t <= t_end);
plot(t(idx), s_gmsk(idx), 'k', 'LineWidth', 1.5);
hold on;
% 添加码元边界
for i = 0:3
    plot([i*Tb, i*Tb], [-1.5, 1.5], 'r--', 'LineWidth', 0.5);
end
title('前3个码元局部放大图');
xlabel('时间 (s)'); ylabel('幅度');
grid on; xlim([t_start, t_end]);

% 子图7：GMSK信号包络
subplot(3, 3, 7);
plot(t, envelope, 'g', 'LineWidth', 1.5);
title('GMSK信号包络');
xlabel('时间 (s)'); ylabel('幅度');
grid on;

% 子图8：GMSK瞬时频率
subplot(3, 3, 8);
plot(t, freq, 'm', 'LineWidth', 1.5);
title('GMSK瞬时频率');
xlabel('时间 (s)'); ylabel('频率 (Hz)');
grid on;

% 子图9：GMSK信号功率谱密度
subplot(3, 3, 9);
[Pxx, F] = pwelch(s_gmsk, [], [], [], fs);
plot(F, 10*log10(Pxx), 'b', 'LineWidth', 1.5);
title('GMSK信号功率谱密度');
xlabel('频率 (Hz)'); ylabel('功率谱密度 (dB/Hz)');
grid on; xlim([0, 5]);

sgtitle('图1：发送端GMSK调制信号波形', 'FontSize', 14, 'FontWeight', 'bold');

%% ================== 图2：GMSK调制过程详细显示 ==================
figure('Position', [100, 100, 1400, 700], 'Name', 'GMSK调制过程详细显示');

% 子图1：原始比特序列（重复显示）
subplot(2, 3, 1);
stem(1:length(bit), bit, 'b', 'LineWidth', 1.5, 'Marker', 'o');
title('原始比特序列');
xlabel('比特序号'); ylabel('比特值');
grid on; xlim([0.5, length(bit)+0.5]);
ylim([-1.5, 1.5]);

% 子图2：GMSK连续相位轨迹（重复显示）
subplot(2, 3, 2);
plot(t_highres, phase, 'b', 'LineWidth', 1.5);
hold on;
% 添加相位跳变点
phase_changes = diff(phase) > 0.5;
phase_change_idx = find(phase_changes) + 1;
plot(t_highres(phase_change_idx), phase(phase_change_idx), 'ro', 'MarkerSize', 8, 'LineWidth', 2);
title('GMSK连续相位轨迹（红点表示相位跳变）');
xlabel('时间 (s)'); ylabel('相位 (rad)');
grid on;

% 子图3：GMSK同相分量 I(t)
subplot(2, 3, 3);
plot(t, I, 'b', 'LineWidth', 1.5);
title('GMSK同相分量 I(t)');
xlabel('时间 (s)'); ylabel('幅度');
grid on;

% 子图4：GMSK正交分量 Q(t)
subplot(2, 3, 4);
plot(t, Q, 'r', 'LineWidth', 1.5);
title('GMSK正交分量 Q(t)');
xlabel('时间 (s)'); ylabel('幅度');
grid on;

% 子图5：发送端GMSK调制信号（重复显示）
subplot(2, 3, 5);
plot(t, s_gmsk, 'k', 'LineWidth', 1.5);
hold on;
% 添加码元边界
for i = 0:bit_count
    plot([i*Tb, i*Tb], [-1.5, 1.5], 'r--', 'LineWidth', 0.5);
end
title('发送端GMSK调制信号（红色虚线为码元边界）');
xlabel('时间 (s)'); ylabel('幅度');
grid on;

% 子图6：同相分量 I 的局部放大
subplot(2, 3, 6);
t_start_local = 2*Tb;
t_end_local = 6*Tb;
idx_local = find(t >= t_start_local & t <= t_end_local);
plot(t(idx_local), I(idx_local), 'b', 'LineWidth', 2);
hold on;
% 添加码元边界和比特值
for i = 2:6
    if i <= length(bit)
        bit_value = bit(i);
        text(i*Tb-0.5*Tb, 1.2, sprintf('b=%d', (bit_value+1)/2), ...
              'FontSize', 10, 'HorizontalAlignment', 'center');
    end
    plot([i*Tb, i*Tb], [-1, 1], 'r--', 'LineWidth', 0.5);
end
title('同相分量 I 的局部放大 (2-6码元)');
xlabel('时间 (s)'); ylabel('幅度');
grid on; xlim([t_start_local, t_end_local]);

sgtitle('图2：GMSK调制过程详细显示', 'FontSize', 14, 'FontWeight', 'bold');

%% ================== 执行完整的Viterbi解码（基于原始代码） ==================
fprintf('\n========== 开始完整Viterbi解码 ==========\n');

% 复制原始代码的完整解码逻辑
E = 1;           % 信号能量
Tb = 1;          % 码元长度
dt = 0.01;       % 时间分辨率

% 状态转移表定义（与原始代码完全相同）
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

% 初始化变量
theta_now = [0 +1 +1];                  % 上一个码元产生后的theta
hamming_head = zeros(8,3);              % 存储前8条路径的汉明距离
hamming_temp1 = [];
hamming_temp2 = [];

path = [];                              % 路径
path_temp = [];
method = 'a';                           % 方法选择：'a'或'b'交替使用
hamming = [];                           % 初始化hamming矩阵

% 主循环：处理每个比特（与原始代码相同）
fprintf('开始解调处理...\n');
for i = 1:length(bit)
    if (i-1 > 2)
        fprintf('正在仿真第%d个码元（8路径后的点）\n', i);
        if (i-1 > 3)
            % 每次调整比较的路径方法
            if (method == 'a')
                method = 'b';
            else
                method = 'a';
            end
        end
    else
        fprintf('正在仿真前3个码元：第%d个码元\n', i);
    end
    
    % 生成当前比特的调制信号（使用原始代码的Generator函数）
    [Sn, Cn, theta_now] = Generator(theta_now, bit(i), i-1, E, Tb, dt);
    
    % 解码当前比特（使用原始代码的GMSKDecoder2函数）
    [path_temp, hamming_temp1, hamming_temp2] = GMSKDecoder2(Sn, Cn, i-1, method, TransferTable, TransferPath, E, Tb, dt);
    
    % 第4个码元时的特殊处理
    if (i == 4)
        % 调整hamming_head矩阵格式
        hamming_head(5:8,1) = hamming_head(2,1);
        hamming_head(1:4,1) = hamming_head(1,1);
        hamming_head(7:8,2) = hamming_head(4,2);
        hamming_head(5:6,2) = hamming_head(3,2);
        hamming_head(3:4,2) = hamming_head(2,2);
        hamming_head(1:2,2) = hamming_head(1,2);
        
        % 计算前3个码元的总路径度量
        hamming = zeros(8,1);
        for j = 1:8
            hamming(j,1) = sum(hamming_head(j,:));
        end
    end
    
    % 存储路径度量
    if (i-1 > 3)
        hamming = [hamming hamming_temp1];
    end
    
    hamming_head = hamming_head + hamming_temp2;
    path = [path path_temp];
end

%% 路径回溯和解码（与原始代码相同）
fprintf('\n开始路径回溯和最终解码...\n');

% 首先检查hamming矩阵的维度
fprintf('hamming矩阵维度: %d x %d\n', size(hamming,1), size(hamming,2));
fprintf('path矩阵维度: %d x %d\n', size(path,1), size(path,2));

tempth = [];
realpath = [];
new_hamming = [];
new_hamming_temp = [];

% 根据path表整理路径
num_segments = size(path,2) / 6;
fprintf('路径段数: %d\n', num_segments);

% 确保hamming矩阵有足够的列
if size(hamming,2) < num_segments + 1
    % 如果hamming列数不足，填充零
    hamming = [hamming, zeros(size(hamming,1), num_segments + 1 - size(hamming,2))];
end

for i = 1:8
    if size(path,2) >= 6
        tempth = path(i,1:6);
        temp = path(i,4:6);
        
        % 初始化hamming_temp，注意索引从2开始
        if size(hamming,2) >= 2
            new_hamming_temp = hamming(i, 2);
        else
            new_hamming_temp = 0;
        end
        
        % 遍历路径段
        for k = 1:num_segments - 1
            if (1 + k*6 <= size(path,2)) && (6 + k*6 <= size(path,2))
                current_segment = path(:,1 + k*6:6 + k*6);
                found = false;
                
                for index = 1:8
                    if all(temp == current_segment(index,1:3))
                        tempth = [tempth current_segment(index, 4:6)];
                        
                        % 修正索引：k+2 改为 k+1（因为从第2列开始）
                        if k+1 <= size(hamming,2)
                            new_hamming_temp = [new_hamming_temp hamming(index, k+1)];
                        else
                            new_hamming_temp = [new_hamming_temp 0];
                        end
                        
                        temp = current_segment(index, 4:6);
                        found = true;
                        break;
                    end
                end
                
                if ~found
                    % 如果没有找到匹配，添加零
                    tempth = [tempth zeros(1,3)];
                    new_hamming_temp = [new_hamming_temp 0];
                end
            else
                % 如果索引超出范围，添加零
                tempth = [tempth zeros(1,3)];
                new_hamming_temp = [new_hamming_temp 0];
            end
        end
    else
        tempth = zeros(1, 3*num_segments);
        new_hamming_temp = zeros(1, num_segments);
    end
    
    realpath = [realpath ; tempth];
    new_hamming = [new_hamming; new_hamming_temp];
end

% 整理路径，使之与TransferTable对应
realpath2 = [];
new_hamming2 = [];
for i = 1:8
    temph = TransferTable(i,10:12);
    for k = 1:8
        if k <= size(realpath,1) && all(temph == realpath(k,1:3))
            realpath2 = [realpath2; realpath(k,:)];
            new_hamming2 = [new_hamming2; new_hamming(k,:)];
            break;
        end
    end
end

% 如果realpath2为空，使用前8行
if isempty(realpath2) && size(realpath,1) >= 8
    realpath2 = realpath(1:8,:);
    new_hamming2 = new_hamming(1:8,:);
end

% 计算最终路径度量
finalhamming = [hamming(:,1) hamming_head new_hamming2];
for i = 1:size(finalhamming,1)
    if ~isempty(finalhamming)
        % 只对非零行求和
        finalhamming(i,1) = sum(finalhamming(i,2:end));
    end
end

% 找到最佳路径
if ~isempty(finalhamming)
    [~, best_path_idx] = max(finalhamming(:,1));
    path_matrix = [TransferTable(:,1:9) realpath2];
    
    % 提取解码比特
    if best_path_idx <= size(path_matrix,1)
        decoded_bits = path_matrix(best_path_idx, 6:3:min(6+3*(bit_count-1), size(path_matrix,2)));
    else
        decoded_bits = [];
    end
else
    best_path_idx = 1;
    decoded_bits = [];
end

% 结果显示
fprintf('\n========== 解调结果 ==========\n');
fprintf('原始比特序列：');
disp(bit);

if ~isempty(decoded_bits)
    fprintf('解码比特序列：');
    disp(decoded_bits);
    
    % 截取或扩展解码比特以匹配原始长度
    if length(decoded_bits) > length(bit)
        decoded_bits = decoded_bits(1:length(bit));
    elseif length(decoded_bits) < length(bit)
        decoded_bits = [decoded_bits, zeros(1, length(bit)-length(decoded_bits))];
    end
    
    % 计算误比特率
    error_bits = sum(decoded_bits ~= bit);
    ber = error_bits / length(bit);
    fprintf('误比特数：%d/%d\n', error_bits, length(bit));
    fprintf('误比特率：%.4f\n', ber);
else
    fprintf('解码比特序列：无有效解码结果\n');
    error_bits = length(bit);
    ber = 1;
end

fprintf('最佳路径编号：%d\n', best_path_idx);
if ~isempty(finalhamming)
    fprintf('最大路径度量值：%.4f\n', finalhamming(best_path_idx,1));
else
    fprintf('最大路径度量值：N/A\n');
end
fprintf('\n================================\n');

%% 生成星座图数据（用于图3）
% 提取接收信号的同相和正交分量
I_received = zeros(1, length(bit)*4);
Q_received = zeros(1, length(bit)*4);

% 使用原始代码的Generator函数生成信号（不加噪声）
theta_now = [0 +1 +1];
for i = 1:length(bit)
    [Sn, Cn, theta_now] = Generator_no_noise(theta_now, bit(i), i-1, E, Tb, dt);
    start_idx = (i-1)*4 + 1;
    end_idx = i*4;
    I_received(start_idx:end_idx) = Sn;
    Q_received(start_idx:end_idx) = Cn;
end

% 采样点（每个码元中心点）
sample_points = 2:4:length(I_received);
I_samples = I_received(sample_points);
Q_samples = Q_received(sample_points);

%% ================== 图3：GMSK解调结果 ==================
figure('Position', [150, 150, 1400, 900], 'Name', 'GMSK解调结果');

% 子图1：原始比特序列与解码比特序列对比
subplot(2, 3, 1);
stem(1:length(bit), bit, 'b', 'LineWidth', 1.5, 'Marker', 'o', 'MarkerSize', 8);
hold on;
if ~isempty(decoded_bits) && length(decoded_bits) == length(bit)
    stem(1:length(decoded_bits), decoded_bits, 'r', 'LineWidth', 1.5, 'Marker', 'x', 'MarkerSize', 8);
    legend('原始比特', '解码比特', 'Location', 'best');
else
    legend('原始比特', 'Location', 'best');
end
title('原始比特序列 vs 解码比特序列');
xlabel('比特序号'); ylabel('比特值');
grid on; xlim([0.5, length(bit)+0.5]);
ylim([-1.5, 1.5]);

% 标记错误比特
if ~isempty(decoded_bits) && length(decoded_bits) == length(bit)
    error_indices = find(decoded_bits ~= bit);
    if ~isempty(error_indices)
        for i = 1:length(error_indices)
            idx = error_indices(i);
            plot(idx, bit(idx), 'ko', 'MarkerSize', 12, 'LineWidth', 2);
            plot(idx, decoded_bits(idx), 'ko', 'MarkerSize', 12, 'LineWidth', 2);
        end
    end
end

% 子图2：最终路径度量值
subplot(2, 3, 2);
if ~isempty(finalhamming) && size(finalhamming,1) >= 1
    bar(1:size(finalhamming,1), finalhamming(:,1), 'b');
    hold on;
    if best_path_idx <= size(finalhamming,1)
        bar(best_path_idx, finalhamming(best_path_idx,1), 'r');
        text(best_path_idx, finalhamming(best_path_idx,1)+0.5, ...
             sprintf('最佳路径: %d\n度量: %.2f', best_path_idx, finalhamming(best_path_idx,1)), ...
             'HorizontalAlignment', 'center', 'FontSize', 10);
    end
    title('最终路径度量值');
    xlabel('路径编号'); ylabel('度量值');
    grid on;
else
    text(0.5, 0.5, '无路径度量数据', 'HorizontalAlignment', 'center');
    title('最终路径度量值');
end

% 子图3：接收信号星座图
subplot(2, 3, 3);
plot(I_samples, Q_samples, 'bo', 'MarkerSize', 8, 'MarkerFaceColor', 'b');
hold on;
% 绘制理想星座点
ideal_points = [-1, -1; -1, 1; 1, -1; 1, 1];
plot(ideal_points(:,1), ideal_points(:,2), 'rx', 'MarkerSize', 15, 'LineWidth', 2);
title('接收信号星座图（无噪声）');
xlabel('同相分量 I'); ylabel('正交分量 Q');
grid on; axis equal;
xlim([-2, 2]); ylim([-2, 2]);
legend('接收采样点', '理想星座点', 'Location', 'best');

% 子图4：误码位置图
subplot(2, 3, 4);
if ~isempty(decoded_bits) && length(decoded_bits) == length(bit)
    error_map = zeros(1, length(bit));
    error_indices = find(decoded_bits ~= bit);
    error_map(error_indices) = 1;
    stem(1:length(error_map), error_map, 'r', 'LineWidth', 2, 'Marker', 'o');
    title('误码位置图');
    xlabel('比特序号'); ylabel('误码标识 (0:正确, 1:错误)');
    grid on; xlim([0.5, length(bit)+0.5]);
    ylim([-0.1, 1.1]);
    set(gca, 'YTick', [0, 1]);
    
    % 添加误码统计
    if ~isempty(error_indices)
        for i = 1:length(error_indices)
            idx = error_indices(i);
            text(idx, 0.5, '误码', ...
                  'HorizontalAlignment', 'center', 'FontSize', 8);
        end
    end
else
    text(0.5, 0.5, '无解码结果', 'HorizontalAlignment', 'center');
    title('误码位置图');
end

% 子图5：路径度量值随码元变化
subplot(2, 3, 5);
if ~isempty(new_hamming2) && size(new_hamming2,2) > 0
    imagesc(new_hamming2);
    colorbar;
    title('路径度量值随码元变化');
    xlabel('码元序号'); ylabel('路径编号');
    colormap('hot');
else
    text(0.5, 0.5, '无路径度量数据', 'HorizontalAlignment', 'center');
    title('路径度量值随码元变化');
end

% 子图6：系统性能总结文字框
subplot(2, 3, 6);
axis off;

% 创建性能总结文本
performance_text = {
    sprintf('系统性能总结');
    sprintf('====================');
    sprintf('比特序列长度: %d', bit_count);
    sprintf('码元长度 Tb: %.2f s', Tb);
    sprintf('带宽时间积 BT: %.2f', BT);
    sprintf('采样频率: %.0f Hz', fs);
    sprintf('误比特数: %d/%d', error_bits, length(bit));
    sprintf('误比特率 BER: %.6f', ber);
    sprintf('解码准确率: %.4f%%', (1-ber)*100);
};

if ~isempty(finalhamming) && best_path_idx <= size(finalhamming,1)
    performance_text{end+1} = sprintf('最佳路径编号: %d', best_path_idx);
    performance_text{end+1} = sprintf('最佳路径度量值: %.2f', finalhamming(best_path_idx,1));
end

% 在图形中显示文本
text_x = 0.1;
text_y = 0.9;
for i = 1:length(performance_text)
    if i == 1
        text(text_x, text_y - (i-1)*0.07, performance_text{i}, ...
             'FontSize', 12, 'FontWeight', 'bold', 'Color', 'b');
    elseif i == 2
        text(text_x, text_y - (i-1)*0.07, performance_text{i}, ...
             'FontSize', 10, 'FontWeight', 'bold');
    else
        text(text_x, text_y - (i-1)*0.07, performance_text{i}, ...
             'FontSize', 10);
    end
end

% 添加矩形框
rectangle('Position', [0.05, 0.05, 0.9, 0.9], 'EdgeColor', 'b', 'LineWidth', 2);

sgtitle(sprintf('图3：GMSK解调结果 (BER=%.6f)', ber), 'FontSize', 14, 'FontWeight', 'bold');

%% ================== 子函数定义 ==================

function [t, s_gmsk, I, Q, phase, freq, envelope, t_highres] = generate_full_gmsk_signal(bits, Tb, fs, BT)
    % 生成完整的GMSK调制信号
    % 输入：
    %   bits - 比特序列（+1/-1）
    %   Tb - 码元长度
    %   fs - 采样频率
    %   BT - 带宽时间积
    % 输出：
    %   t - 时间向量
    %   s_gmsk - GMSK调制信号
    %   I - 同相分量
    %   Q - 正交分量
    %   phase - 相位轨迹
    %   freq - 瞬时频率
    %   envelope - 包络
    %   t_highres - 高分辨率时间向量（用于相位）
    
    % 时间向量
    total_time = length(bits) * Tb;
    t = 0:1/fs:total_time-1/fs;
    t_highres = 0:1/(10*fs):total_time-1/(10*fs);
    
    % 高斯滤波器参数
    B = BT / Tb;  % 3dB带宽
    alpha = sqrt(log(2)) / (2*pi*B*Tb);
    
    % 生成高斯脉冲
    gaussian_pulse = gaussian_filter(Tb, fs, alpha);
    
    % 生成相位脉冲响应
    phase_pulse = cumsum(gaussian_pulse) / fs;
    phase_pulse = phase_pulse / max(phase_pulse) * pi/2;
    
    % 生成相位轨迹
    phase = zeros(size(t_highres));
    for i = 1:length(bits)
        bit_time = (i-1)*Tb;
        idx = find(t_highres >= bit_time & t_highres < bit_time + Tb);
        if ~isempty(idx)
            % 确保相位脉冲长度匹配
            pulse_length = min(length(phase_pulse), length(idx));
            phase(idx(1:pulse_length)) = phase(idx(1:pulse_length)) + bits(i) * phase_pulse(1:pulse_length);
        end
    end
    
    % 计算累积相位
    phase = cumsum(phase) * 2*pi;
    
    % 插值相位到标准时间向量
    phase_interp = interp1(t_highres, phase, t, 'linear');
    
    % 生成同相和正交分量
    I = cos(phase_interp);
    Q = sin(phase_interp);
    
    % 生成GMSK调制信号
    s_gmsk = I .* cos(2*pi*0.3*t) - Q .* sin(2*pi*0.3*t);
    
    % 计算包络
    envelope = sqrt(I.^2 + Q.^2);
    
    % 计算瞬时频率
    freq = diff(phase_interp) * fs / (2*pi);
    freq = [freq(1), freq];  % 保持相同长度
end

function gaussian_pulse = gaussian_filter(Tb, fs, alpha)
    % 生成高斯滤波器脉冲响应
    t = -2*Tb:1/fs:2*Tb;
    gaussian_pulse = 1/(sqrt(2*pi)*alpha) * exp(-t.^2/(2*alpha^2));
    gaussian_pulse = gaussian_pulse / sum(gaussian_pulse);  % 归一化
end

function [Sn, Cn, next_theta] = Generator_no_noise(theta, bit, n, E, Tb, dt)
    % 信号产生程序（无噪声版本，用于星座图）
    % 根据theta、bit和n产生发送的信号，不加噪声
    if nargin < 6
        dt = 0.01;
    end
    if nargin < 5
        Tb = 1;
    end
    if nargin < 4
        E = 1;
    end
    
    next_theta = [theta(1) + theta(2) * pi/2, theta(3), bit];  % 计算theta值
    [Sn, Cn] = recover([next_theta theta], n, E, Tb, dt);      % 利用theta产生信号
    % 不加噪声
end

% 以下是原始代码中的函数（保持不变）
function [Sn, Cn, next_theta] = Generator(theta, bit, n, E, Tb, dt)
    % 信号产生程序
    % 根据theta、bit和n产生发送的信号，并加上噪声
    if nargin < 6
        dt = 0.01;
    end
    if nargin < 5
        Tb = 1;
    end
    if nargin < 4
        E = 1;
    end
    
    next_theta = [theta(1) + theta(2) * pi/2, theta(3), bit];  % 计算theta值
    [Sn, Cn] = recover([next_theta theta], n, E, Tb, dt);      % 利用theta产生信号
    Sn = Sn + 0.5*randn(1, length(Sn));                        % 同相加噪
    Cn = Cn + 0.5*randn(1, length(Cn));                        % 正交加噪
end

function [Sn, Cn] = recover(TransferPath, n, E, Tb, dt)
    % 恢复函数：计算出相位值，然后产生同相和正交分量
    if nargin < 5
        dt = 0.01;
    end
    if nargin < 4
        Tb = 1;
    end
    if nargin < 3
        E = 1;
    end
    
    % 定义高斯脉冲整形函数
    gt = @(t) (erfc(2*pi*0.3*(t - 2) / sqrt(2*log(2))) - ...
               erfc(2*pi*0.3*(t + 1) / sqrt(2*log(2)))) / 2;
    
    % 采样时间点
    t = [0.1*Tb 0.3*Tb 0.5*Tb 0.8*Tb];
    
    % 计算不同时间偏移
    tn_1 = t - (n - 1)*Tb;
    tn_2 = t - (n - 2)*Tb;
    tn   = t - n*Tb;
    
    % 初始化结果向量
    rtn_1 = [];
    rtn_2 = [];
    rtn   = [];
    
    % 积分计算相位
    for i = 1:length(t)
        rtn_1 = [rtn_1   integral(gt, -0.1, tn_1(i)) / (2*Tb)];
        rtn_2 = [rtn_2   integral(gt, -0.1, tn_2(i)) / (2*Tb)];
        rtn   = [rtn     integral(gt, -0.1, tn(i))   / (2*Tb)];
    end
    
    % 计算相位：TransferPath结构为[On an_1 an On_1 an_2 an_1]
    rtn_1 = rtn_1 .* pi .* TransferPath(2);
    rtn_2 = rtn_2 .* pi .* TransferPath(5);
    rtn   = rtn   .* pi .* TransferPath(3);
    
    % 总相位
    fai = rtn + rtn_1 + rtn_2 + TransferPath(1);
    
    % 生成同相和正交分量
    Sn = [];
    Cn = [];
    for i = 1:length(t)
        Sn = [Sn sqrt(2*E/Tb) * cos(fai(i))];
        Cn = [Cn sqrt(2*E/Tb) * sin(fai(i))];
    end
end

function [path, hamming, hamming_head] = GMSKDecoder2(Sn, Cn, n, method, TransferTable, TransferPath, E, Tb, dt)
    % GMSK解码函数
    path = [];              % 存储路径
    temp_path = [];
    temp_hamming = [];
    hamming_head = zeros(8,3);  % 存储头3个码元的路径度量值
    hamming = [];               % 存储之后码元的路径度量值
    
    if nargin < 9
        dt = 0.01;
    end
    if nargin < 8
        Tb = 1;
    end
    if nargin < 7
        E = 1;
    end
    
    index = 1;
    
    % 前3个码元的计算
    if (n <= 2)
        for i = 1:2^(n+1)
            if index <= size(TransferTable,1)
                [Sn1, Cn1] = recover([TransferTable(index, (1 + n*3 + 3):(6 + n*3)) ...
                                      TransferTable(index, (1 + n*3):(1 + n*3 + 2))], n, E, Tb, dt);
                result1 = dot(Sn1, Sn) + dot(Cn1, Cn);
                hamming_head(i, n+1) = result1;
                index = index + 2^(2 - n);
            end
        end
    else
        % 3个码元之后的码元计算
        switch method
            case 'a'  % 方法a：计算TransferPath中的前8个节点
                for idx = 1:8
                    if idx <= size(TransferPath,1)
                        [Sn1, Cn1] = recover(TransferPath(idx, 1:6), n, E, Tb, dt);
                        [Sn2, Cn2] = recover([TransferPath(idx, 1:3) TransferPath(idx, 7:9)], n, E, Tb, dt);
                        result1 = dot(Sn1, Sn) + dot(Cn1, Cn);
                        result2 = dot(Sn2, Sn) + dot(Cn2, Cn);
                        
                        if (result1 >= result2)
                            temp_path = [temp_path; TransferPath(idx, 4:6) TransferPath(idx, 1:3)];
                            temp_hamming = [temp_hamming; result1];
                        else
                            temp_path = [temp_path; TransferPath(idx, 7:9) TransferPath(idx, 1:3)];
                            temp_hamming = [temp_hamming; result2];
                        end
                    end
                end
                if ~isempty(temp_path)
                    path = [path temp_path];
                end
                if ~isempty(temp_hamming)
                    hamming = [hamming temp_hamming];
                end
                
            case 'b'  % 方法b：计算TransferPath中的后8个节点
                for idx = 9:16
                    if idx <= size(TransferPath,1)
                        [Sn1, Cn1] = recover(TransferPath(idx, 1:6), n, E, Tb, dt);
                        [Sn2, Cn2] = recover([TransferPath(idx, 1:3) TransferPath(idx, 7:9)], n, E, Tb, dt);
                        result1 = dot(Sn1, Sn) + dot(Cn1, Cn);
                        result2 = dot(Sn2, Sn) + dot(Cn2, Cn);
                        
                        if (result1 >= result2)
                            temp_path = [temp_path; TransferPath(idx, 4:6) TransferPath(idx, 1:3)];
                            temp_hamming = [temp_hamming; result1];
                        else
                            temp_path = [temp_path; TransferPath(idx, 7:9) TransferPath(idx, 1:3)];
                            temp_hamming = [temp_hamming; result2];
                        end
                    end
                end
                if ~isempty(temp_path)
                    path = [path temp_path];
                end
                if ~isempty(temp_hamming)
                    hamming = [hamming temp_hamming];
                end
        end
    end
end