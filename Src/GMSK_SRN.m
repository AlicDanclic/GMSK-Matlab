%% GMSK信号解调仿真程序 - 带误码率曲线版本（信噪比变化）
% 作者：基于原始代码修改
% 功能：测试不同信噪比下GMSK信号的误码率并绘制曲线

clear; clc; close all;

%% 全局参数设置
E = 1;           % 信号能量
Tb = 1;          % 码元长度
dt = 0.01;       % 时间分辨率
bit_count = 100;  % 固定比特序列长度

%% 状态转移表定义（保持不变）
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

%% 定义要测试的信噪比范围（dB）
SNR_dB = 0:2:20;  % 信噪比从0dB到20dB，步长为2dB
% SNR_dB = 0:1:10;  % 或者更密集的信噪比测试

num_trials = 10;  % 每个信噪比的仿真次数

ber_results = zeros(length(SNR_dB), 1);  % 存储每个信噪比的平均误码率
std_results = zeros(length(SNR_dB), 1);  % 存储误码率的标准差

fprintf('开始误码率测试，比特长度固定为: %d\n', bit_count);
fprintf('测试信噪比范围: %d dB 到 %d dB\n', min(SNR_dB), max(SNR_dB));
fprintf('每种信噪比仿真 %d 次\n\n', num_trials);

%% 主循环：测试不同信噪比
for snr_idx = 1:length(SNR_dB)
    SNR = SNR_dB(snr_idx);
    fprintf('正在测试信噪比: %.1f dB\n', SNR);
    
    ber_temp = zeros(num_trials, 1);  % 存储当前信噪比的所有仿真误码率
    
    % 对每个信噪比进行多次仿真
    for trial = 1:num_trials
        %% 以下是原始代码的主体部分，添加SNR参数
        % 生成随机比特序列（-1和+1）
        bit = 2 * randi([0, 1], 1, bit_count) - 1;
        
        % 初始化变量
        theta_now = [0 +1 +1];                  % 上一个码元产生后的theta
        hamming_head = zeros(8,3);              % 存储前8条路径的汉明距离
        hamming_temp1 = [];
        hamming_temp2 = [];

        path = [];                              % 路径
        path_temp = [];
        method = 'a';                           % 方法选择：'a'或'b'交替使用
        hamming = [];                           % 初始化hamming矩阵

        % 主循环：处理每个比特
        for i = 1:length(bit)
            if (i-1 > 2)
                if (i-1 > 3)
                    % 每次调整比较的路径方法
                    if (method == 'a')
                        method = 'b';
                    else
                        method = 'a';
                    end
                end
            end
            
            % 生成当前比特的调制信号（传入SNR参数）
            [Sn, Cn, theta_now] = Generator_SNR(theta_now, bit(i), i-1, E, Tb, dt, SNR);
            
            % 解码当前比特
            [path_temp, hamming_temp1, hamming_temp2] = GMSKDecoder2_SNR(Sn, Cn, i-1, method, TransferTable, TransferPath, E, Tb, dt);
            
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
                if isempty(hamming)
                    hamming = hamming_temp1;
                else
                    hamming = [hamming hamming_temp1];
                end
            end
            
            if ~isempty(hamming_temp2)
                hamming_head = hamming_head + hamming_temp2;
            end
            
            if ~isempty(path_temp)
                path = [path path_temp];
            end
        end

        %% 路径回溯和解码 - 修复维度问题
        tempth = [];
        realpath = [];
        new_hamming = [];
        new_hamming_temp = [];

        % 根据path表整理路径
        if ~isempty(path) && size(path,2) >= 6
            num_segments = floor(size(path,2) / 6);
        else
            num_segments = 0;
        end

        % 确保hamming矩阵有足够的列
        if ~isempty(hamming) && size(hamming,2) < num_segments + 1
            % 如果hamming列数不足，填充零
            hamming = [hamming, zeros(size(hamming,1), num_segments + 1 - size(hamming,2))];
        elseif isempty(hamming) && num_segments > 0
            hamming = zeros(8, num_segments + 1);
        end

        for i = 1:8
            if ~isempty(path) && size(path,2) >= 6
                tempth = path(i,1:6);
                temp = path(i,4:6);
                
                % 初始化hamming_temp，注意索引从2开始
                if ~isempty(hamming) && size(hamming,2) >= 2
                    new_hamming_temp = hamming(i, 2);
                else
                    new_hamming_temp = 0;
                end
                
                % 遍历路径段
                for k = 1:max(0, num_segments - 1)
                    if (1 + k*6 <= size(path,2)) && (6 + k*6 <= size(path,2))
                        current_segment = path(:,1 + k*6:6 + k*6);
                        found = false;
                        
                        for index = 1:min(8, size(current_segment,1))
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
                tempth = zeros(1, 3*max(1, num_segments));
                new_hamming_temp = zeros(1, max(1, num_segments));
            end
            
            realpath = [realpath ; tempth];
            new_hamming = [new_hamming; new_hamming_temp];
        end

        % 整理路径，使之与TransferTable对应
        realpath2 = [];
        new_hamming2 = [];
        
        if ~isempty(realpath) && size(realpath,1) >= 1
            for i = 1:8
                temph = TransferTable(i,10:12);
                found = false;
                for k = 1:min(8, size(realpath,1))
                    if k <= size(realpath,1) && all(temph == realpath(k,1:3))
                        realpath2 = [realpath2; realpath(k,:)];
                        if k <= size(new_hamming,1)
                            new_hamming2 = [new_hamming2; new_hamming(k,:)];
                        else
                            new_hamming2 = [new_hamming2; zeros(1, size(new_hamming,2))];
                        end
                        found = true;
                        break;
                    end
                end
                if ~found
                    realpath2 = [realpath2; zeros(1, size(realpath,2))];
                    new_hamming2 = [new_hamming2; zeros(1, size(new_hamming,2))];
                end
            end
        else
            realpath2 = zeros(8, 3*max(1, num_segments));
            new_hamming2 = zeros(8, max(1, num_segments));
        end

        % 如果realpath2为空，使用前8行
        if isempty(realpath2) && size(realpath,1) >= 8
            realpath2 = realpath(1:8,:);
            new_hamming2 = new_hamming(1:8,:);
        end

        % 确保所有矩阵维度一致
        if size(realpath2,1) < 8
            realpath2 = [realpath2; zeros(8-size(realpath2,1), size(realpath2,2))];
        end
        if size(new_hamming2,1) < 8
            new_hamming2 = [new_hamming2; zeros(8-size(new_hamming2,1), size(new_hamming2,2))];
        end
        
        % 确保hamming矩阵维度正确
        if isempty(hamming)
            hamming = zeros(8, 1);
        elseif size(hamming,1) < 8
            hamming = [hamming; zeros(8-size(hamming,1), size(hamming,2))];
        end
        
        % 确保hamming_head维度正确
        if size(hamming_head,1) < 8
            hamming_head = [hamming_head; zeros(8-size(hamming_head,1), 3)];
        end

        % 计算最终路径度量 - 修复维度不匹配问题
        if ~isempty(hamming) && ~isempty(hamming_head) && ~isempty(new_hamming2)
            % 确保所有矩阵有相同的行数
            min_rows = min([size(hamming,1), size(hamming_head,1), size(new_hamming2,1)]);
            
            if min_rows > 0
                finalhamming = [hamming(1:min_rows,1) hamming_head(1:min_rows,:) new_hamming2(1:min_rows,:)];
                
                % 计算每行的总路径度量
                for i = 1:size(finalhamming,1)
                    if ~isempty(finalhamming)
                        % 只对非零行求和
                        finalhamming(i,1) = sum(finalhamming(i,2:end));
                    end
                end
            else
                finalhamming = zeros(8, 1);
            end
        else
            finalhamming = zeros(8, 1);
        end

        % 找到最佳路径
        if ~isempty(finalhamming) && size(finalhamming,1) > 0
            [~, best_path_idx] = max(finalhamming(:,1));
            
            % 确保路径矩阵维度正确
            if best_path_idx <= size(realpath2,1)
                % 创建完整的路径矩阵
                if size(TransferTable,1) >= 8 && size(realpath2,1) >= 8
                    path_matrix = [TransferTable(:,1:9) realpath2];
                    
                    % 提取解码比特
                    if best_path_idx <= size(path_matrix,1)
                        % 计算最大可提取的比特数
                        max_bits = min(bit_count, floor((size(path_matrix,2) - 5) / 3));
                        if max_bits > 0
                            decoded_bits = path_matrix(best_path_idx, 6:3:6+3*(max_bits-1));
                        else
                            decoded_bits = [];
                        end
                    else
                        decoded_bits = [];
                    end
                else
                    decoded_bits = [];
                end
            else
                decoded_bits = [];
            end
        else
            best_path_idx = 1;
            decoded_bits = [];
        end
        
        %% 计算本次仿真的误码率
        if ~isempty(decoded_bits) && length(decoded_bits) >= 1
            % 截取或扩展解码比特以匹配原始长度
            if length(decoded_bits) > length(bit)
                decoded_bits = decoded_bits(1:length(bit));
            elseif length(decoded_bits) < length(bit)
                decoded_bits = [decoded_bits, zeros(1, length(bit)-length(decoded_bits))];
            end
            
            % 计算误比特率
            error_bits = sum(decoded_bits ~= bit);
            ber = error_bits / length(bit);
        else
            ber = 1;  % 如果解码失败，误码率为1
        end
        
        ber_temp(trial) = ber;
    end
    
    % 计算当前信噪比的平均误码率和标准差
    ber_results(snr_idx) = mean(ber_temp);
    std_results(snr_idx) = std(ber_temp);
    
    fprintf('  信噪比 %.1f dB: 平均误码率 = %.4f, 标准差 = %.4f\n', ...
        SNR, ber_results(snr_idx), std_results(snr_idx));
end

%% 绘制误码率曲线
figure('Position', [100, 100, 1400, 600]);

% 子图1：误码率随信噪比变化曲线（普通坐标）
subplot(1,3,1);
errorbar(SNR_dB, ber_results, std_results, 'b-o', 'LineWidth', 2, ...
    'MarkerSize', 8, 'MarkerFaceColor', 'b', 'CapSize', 10);
grid on;
xlabel('信噪比 (dB)', 'FontSize', 12);
ylabel('误码率 (BER)', 'FontSize', 12);
title('GMSK解调误码率随信噪比变化', 'FontSize', 14);
legend('误码率（带误差棒）', 'Location', 'best');

% 添加数据标签
for i = 1:length(SNR_dB)
    if ber_results(i) > 0
        text(SNR_dB(i), ber_results(i)*1.2, sprintf('%.4f', ber_results(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 10);
    end
end

% 子图2：误码率随信噪比变化曲线（对数坐标）
subplot(1,3,2);
semilogy(SNR_dB, ber_results, 'r-s', 'LineWidth', 2, ...
    'MarkerSize', 8, 'MarkerFaceColor', 'r');
hold on;
grid on;
xlabel('信噪比 (dB)', 'FontSize', 12);
ylabel('误码率 (BER, 对数坐标)', 'FontSize', 12);
title('GMSK解调误码率（对数坐标）', 'FontSize', 14);
legend('GMSK误码率曲线', 'Location', 'best');

% 添加理论曲线参考（AWGN信道中BPSK的理论误码率）
if exist('berawgn', 'file')  % 如果通信工具箱可用
    % BPSK的理论误码率作为参考
    SNR_linear = 10.^(SNR_dB/10);
    theory_ber = berawgn(SNR_dB, 'psk', 2, 'nondiff');
    semilogy(SNR_dB, theory_ber, 'g--', 'LineWidth', 1.5);
    legend('GMSK误码率曲线', 'BPSK理论误码率', 'Location', 'best');
end

% 子图3：误码率变化趋势（分贝增益）
subplot(1,3,3);
% 计算相对于0dB的增益
if ber_results(1) > 0
    gain_dB = 10*log10(ber_results(1)./ber_results);
    plot(SNR_dB, gain_dB, 'm-^', 'LineWidth', 2, ...
        'MarkerSize', 8, 'MarkerFaceColor', 'm');
    grid on;
    xlabel('信噪比 (dB)', 'FontSize', 12);
    ylabel('相对于0dB的误码率增益 (dB)', 'FontSize', 12);
    title('误码率改善增益', 'FontSize', 14);
    
    % 添加数据标签
    for i = 1:length(SNR_dB)
        text(SNR_dB(i), gain_dB(i)+0.5, sprintf('%.1f dB', gain_dB(i)), ...
            'HorizontalAlignment', 'center', 'FontSize', 9);
    end
else
    text(0.5, 0.5, '无法计算增益（0dB处误码率为0）', ...
        'HorizontalAlignment', 'center', 'FontSize', 12);
    title('误码率改善增益', 'FontSize', 14);
end

sgtitle(sprintf('GMSK解调误码率曲线 (比特长度=%d, 每种信噪比仿真%d次)', bit_count, num_trials), 'FontSize', 16);

%% 绘制误码率瀑布图（如果需要）
figure('Position', [100, 100, 800, 600]);
imagesc(SNR_dB, 1:num_trials, reshape(ber_temp, [], length(SNR_dB))');
colorbar;
xlabel('信噪比 (dB)', 'FontSize', 12);
ylabel('仿真次数', 'FontSize', 12);
title('各次仿真误码率分布', 'FontSize', 14);
colormap(jet);

%% 显示统计结果
fprintf('\n========== 误码率测试结果汇总 ==========\n');
fprintf('信噪比(dB)\t平均误码率\t标准差\t\t相对于0dB的增益(dB)\n');
fprintf('--------------------------------------------------------------\n');
for i = 1:length(SNR_dB)
    if i == 1
        gain = 0;
    elseif ber_results(1) > 0 && ber_results(i) > 0
        gain = 10*log10(ber_results(1)/ber_results(i));
    else
        gain = NaN;
    end
    
    if isnan(gain)
        fprintf('%8.1f\t%12.4f\t%8.4f\t%20s\n', SNR_dB(i), ber_results(i), std_results(i), 'N/A');
    else
        fprintf('%8.1f\t%12.4f\t%8.4f\t%20.1f\n', SNR_dB(i), ber_results(i), std_results(i), gain);
    end
end
fprintf('==============================================================\n');

% 计算总体统计
fprintf('\n总体统计：\n');
fprintf('平均误码率（所有信噪比）：%.4f\n', mean(ber_results(ber_results>0)));
[min_ber, min_idx] = min(ber_results);
fprintf('最小误码率：%.4f (信噪比：%.1f dB)\n', min_ber, SNR_dB(min_idx));
[max_ber, max_idx] = max(ber_results);
fprintf('最大误码率：%.4f (信噪比：%.1f dB)\n', max_ber, SNR_dB(max_idx));

%% 计算并显示关键性能指标
fprintf('\n关键性能指标：\n');
% 找出误码率首次低于0.1、0.01、0.001的信噪比
thresholds = [0.1, 0.01, 0.001, 0.0001];
for th = thresholds
    idx = find(ber_results <= th, 1, 'first');
    if ~isempty(idx)
        fprintf('误码率首次低于 %.4f 的信噪比: %.1f dB\n', th, SNR_dB(idx));
    else
        fprintf('误码率未达到低于 %.4f 的水平\n', th);
    end
end

%% ================== 修改后的子函数定义（添加SNR参数）==================

function [Sn, Cn, next_theta] = Generator_SNR(theta, bit, n, E, Tb, dt, SNR_dB)
% 信号产生程序（带SNR参数）
% 根据theta、bit和n产生发送的信号，并加上噪声
    if nargin < 7
        SNR_dB = 10;  % 默认信噪比
    end
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
    
    % 根据SNR计算噪声功率
    SNR_linear = 10^(SNR_dB/10);  % 将dB转换为线性值
    
    % 计算信号功率
    signal_power = mean(Sn.^2 + Cn.^2);
    
    % 计算噪声标准差
    noise_std = sqrt(signal_power / (2 * SNR_linear));
    
    % 添加高斯白噪声
    Sn = Sn + noise_std * randn(1, length(Sn));
    Cn = Cn + noise_std * randn(1, length(Cn));
end

function [path, hamming, hamming_head] = GMSKDecoder2_SNR(Sn, Cn, n, method, TransferTable, TransferPath, E, Tb, dt)
% GMSK解码函数（与原始相同，但为了保持一致性重命名）
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
                    path = temp_path;
                end
                if ~isempty(temp_hamming)
                    hamming = temp_hamming;
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
                    path = temp_path;
                end
                if ~isempty(temp_hamming)
                    hamming = temp_hamming;
                end
        end
    end
end

%% ================== 原有的子函数（保持不变）==================

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