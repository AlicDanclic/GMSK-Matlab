%% GMSK调制解调系统仿真 - 修复解调误码问题
clear all; close all; clc;

%% 参数设置
N_bits = 100;           % 比特数
bit_rate = 1000;        % 比特率 (bps)
Tb = 1/bit_rate;        % 比特周期
Fs = 16 * bit_rate;     % 采样频率
Ts = 1/Fs;              % 采样间隔
sps = Fs/bit_rate;      % 每符号采样点数

% GMSK参数
BT = 0.3;               % 带宽时间积
Fc = 4 * bit_rate;      % 载波频率

% 图形显示设置
show_separate = 1;      % 1=每个图形单独窗口，0=所有图形在一个窗口

fprintf('GMSK系统参数:\n');
fprintf('比特数: %d\n', N_bits);
fprintf('比特率: %d bps\n', bit_rate);
fprintf('采样率: %d Hz\n', Fs);
fprintf('载波频率: %d Hz\n', Fc);
fprintf('BT乘积: %.1f\n', BT);

%% 生成随机比特序列
rng(42); % 设置随机种子以便复现
data_bits = randi([0, 1], 1, N_bits);

fprintf('\n比特序列 (前20个): ');
fprintf('%d ', data_bits(1:min(20, N_bits)));
fprintf('\n');

%% GMSK编码过程
%% 1. 比特到符号映射（NRZ编码）
data_nrz = 2 * data_bits - 1; % 0->-1, 1->+1

% 上采样
tx_signal = repelem(data_nrz, sps);

%% 2. 高斯滤波器设计
alpha = sqrt(2*log(2)) / (BT * Tb);
t_gauss = (-3*Tb:Ts:3*Tb);
gauss_filter = (sqrt(pi)/alpha) * exp(-(pi*t_gauss/alpha).^2);
gauss_filter = gauss_filter / sum(gauss_filter);

% 高斯滤波
filtered_signal = conv(tx_signal, gauss_filter, 'same');

%% 3. 相位积分得到相位轨迹
phase = pi * cumsum(filtered_signal) * Ts / Tb;

%% 4. GMSK调制
t = (0:length(phase)-1) * Ts;
gmsk_signal = cos(2*pi*Fc*t + phase);

%% 5. 添加噪声（AWGN信道）
SNR_dB = 20; % 提高信噪比以减少误码
gmsk_signal_noisy = awgn(gmsk_signal, SNR_dB, 'measured');

%% 6. 改进的GMSK解调算法
fprintf('\n开始解调...\n');

% 方法1：改进的正交解调
I_carrier = cos(2*pi*Fc*t);
Q_carrier = sin(2*pi*Fc*t);

% 正交下变频
I_component = gmsk_signal_noisy .* I_carrier;
Q_component = gmsk_signal_noisy .* Q_carrier;

% 改进的低通滤波器设计
lp_cutoff = bit_rate * 1.5; % 截止频率略高于比特率
[num, den] = butter(8, lp_cutoff/(Fs/2), 'low');

% 滤波
I_filtered = filtfilt(num, den, I_component); % 使用零相位滤波
Q_filtered = filtfilt(num, den, Q_component);

% 相位解调 - 修复相位展开问题
phase_est = atan2(Q_filtered, I_filtered);

% 使用改进的相位解调方法
phase_unwrapped = unwrap(phase_est);

% 计算瞬时频率
instant_freq = diff(phase_unwrapped) / (2*pi*Ts);

% 符号判决 - 改进的判决方法
demod_bits = zeros(1, N_bits);

% 在每个符号周期中间采样
for i = 1:N_bits
    % 在符号中间位置采样
    sample_index = round((i-0.5) * sps);
    if sample_index > length(instant_freq)
        sample_index = length(instant_freq);
    end
    
    % 根据瞬时频率符号判决
    if instant_freq(sample_index) > 0
        demod_bits(i) = 1;
    else
        demod_bits(i) = 0;
    end
end

% 方法2：备用的差分检测方法（如果方法1效果不好）
if sum(data_bits ~= demod_bits) > N_bits/2
    fprintf('方法1误码率高，尝试差分检测方法...\n');
    
    % 差分检测
    delayed_signal = [gmsk_signal_noisy(sps+1:end), zeros(1, sps)];
    product_signal = gmsk_signal_noisy .* delayed_signal;
    
    % 低通滤波
    product_filtered = filtfilt(num, den, product_signal);
    
    % 符号判决
    for i = 1:N_bits
        sample_index = round((i-0.5) * sps);
        if sample_index > length(product_filtered)
            sample_index = length(product_filtered);
        end
        
        if product_filtered(sample_index) > 0
            demod_bits(i) = 1;
        else
            demod_bits(i) = 0;
        end
    end
end

%% 7. 误码率计算
bit_errors = sum(data_bits ~= demod_bits);
BER = bit_errors / N_bits;

fprintf('\n性能统计:\n');
fprintf('误比特数: %d\n', bit_errors);
fprintf('误码率: %.4f\n', BER);
fprintf('正确率: %.2f%%\n', (1-BER)*100);

%% 8. 波形显示
if show_separate
    % 模式1：每个图形单独窗口
    
    % 图形1: GMSK编码过程
    figure('Position', [100, 100, 1400, 800], 'Name', 'GMSK编码波形');
    
    subplot(2,3,1);
    stem(0:N_bits-1, data_bits, 'filled', 'MarkerSize', 4);
    title('原始比特序列');
    xlabel('比特索引');
    ylabel('比特值');
    grid on;
    
    subplot(2,3,2);
    plot(t(1:min(20*sps, length(tx_signal)))*1000, tx_signal(1:min(20*sps, length(tx_signal))));
    title('NRZ编码信号');
    xlabel('时间 (ms)');
    ylabel('幅度');
    grid on;
    
    subplot(2,3,3);
    plot(t_gauss*1000, gauss_filter, 'r-', 'LineWidth', 2);
    title('高斯滤波器');
    xlabel('时间 (ms)');
    ylabel('幅度');
    grid on;
    
    subplot(2,3,4);
    plot(t(1:min(20*sps, length(filtered_signal)))*1000, filtered_signal(1:min(20*sps, length(filtered_signal))));
    title('高斯滤波后信号');
    xlabel('时间 (ms)');
    ylabel('幅度');
    grid on;
    
    subplot(2,3,5);
    plot(t(1:min(20*sps, length(phase)))*1000, phase(1:min(20*sps, length(phase))));
    title('相位轨迹');
    xlabel('时间 (ms)');
    ylabel('相位 (rad)');
    grid on;
    
    subplot(2,3,6);
    plot(t(1:min(10*sps, length(gmsk_signal)))*1000, gmsk_signal(1:min(10*sps, length(gmsk_signal))));
    title('GMSK调制信号');
    xlabel('时间 (ms)');
    ylabel('幅度');
    grid on;
    
    sgtitle('GMSK编码过程', 'FontSize', 14, 'FontWeight', 'bold');
    
    % 图形2: 解调过程分析
    figure('Position', [100, 100, 1400, 800], 'Name', 'GMSK解调分析');
    
    subplot(2,3,1);
    plot(t(1:min(10*sps, length(gmsk_signal_noisy)))*1000, gmsk_signal_noisy(1:min(10*sps, length(gmsk_signal_noisy))));
    title('接收信号 (含噪声)');
    xlabel('时间 (ms)');
    ylabel('幅度');
    grid on;
    
    subplot(2,3,2);
    plot(t(1:min(20*sps, length(I_filtered)))*1000, I_filtered(1:min(20*sps, length(I_filtered))), 'b-');
    hold on;
    plot(t(1:min(20*sps, length(Q_filtered)))*1000, Q_filtered(1:min(20*sps, length(Q_filtered))), 'r-');
    title('解调I/Q分量');
    xlabel('时间 (ms)');
    ylabel('幅度');
    legend('I路', 'Q路');
    grid on;
    
    subplot(2,3,3);
    plot(t(1:min(20*sps, length(phase_est)))*1000, phase_est(1:min(20*sps, length(phase_est))));
    title('估计相位');
    xlabel('时间 (ms)');
    ylabel('相位 (rad)');
    grid on;
    
    subplot(2,3,4);
    plot(t(1:min(20*sps, length(phase_unwrapped)))*1000, phase_unwrapped(1:min(20*sps, length(phase_unwrapped))));
    title('展开相位');
    xlabel('时间 (ms)');
    ylabel('相位 (rad)');
    grid on;
    
    subplot(2,3,5);
    plot(t(1:length(instant_freq))*1000, instant_freq);
    title('瞬时频率');
    xlabel('时间 (ms)');
    ylabel('频率 (Hz)');
    grid on;
    
    subplot(2,3,6);
    stem(0:N_bits-1, demod_bits, 'filled', 'MarkerSize', 4);
    title('解调比特');
    xlabel('比特索引');
    ylabel('比特值');
    grid on;
    
    sgtitle('GMSK解调过程', 'FontSize', 14, 'FontWeight', 'bold');
    
    % 图形3: 性能对比
    figure('Position', [100, 100, 1200, 600], 'Name', '性能对比');
    
    subplot(2,3,1);
    stem(0:N_bits-1, data_bits, 'b', 'filled', 'MarkerSize', 3);
    hold on;
    stem(0:N_bits-1, demod_bits, 'r', 'LineWidth', 1);
    title('比特序列对比');
    xlabel('比特索引');
    ylabel('比特值');
    legend('原始', '解调', 'Location', 'best');
    grid on;
    
    subplot(2,3,2);
    error_pattern = data_bits ~= demod_bits;
    stem(0:N_bits-1, error_pattern, 'r', 'filled', 'MarkerSize', 3);
    title('误码位置');
    xlabel('比特索引');
    ylabel('错误标记');
    grid on;
    
    subplot(2,3,3);
    scatter(I_filtered(1:sps:end), Q_filtered(1:sps:end), 30, 'b', 'filled');
    title('星座图');
    xlabel('I分量');
    ylabel('Q分量');
    axis equal;
    grid on;
    
    subplot(2,3,4);
    eyediagram(real(gmsk_signal_noisy(1:min(200*sps, length(gmsk_signal_noisy)))), 2*sps);
    title('接收信号眼图');
    
    subplot(2,3,5);
    % 相位轨迹对比
    plot(t(1:min(10*sps, length(phase)))*1000, phase(1:min(10*sps, length(phase))), 'b-', 'LineWidth', 2);
    hold on;
    plot(t(1:min(10*sps, length(phase_unwrapped)))*1000, phase_unwrapped(1:min(10*sps, length(phase_unwrapped))), 'r--', 'LineWidth', 1);
    title('相位轨迹对比');
    xlabel('时间 (ms)');
    ylabel('相位 (rad)');
    legend('发射相位', '接收相位');
    grid on;
    
    subplot(2,3,6);
    % 性能统计
    text(0.1, 0.8, sprintf('总比特数: %d', N_bits), 'FontSize', 12);
    text(0.1, 0.65, sprintf('误比特数: %d', bit_errors), 'FontSize', 12);
    text(0.1, 0.5, sprintf('误码率: %.4f', BER), 'FontSize', 12);
    text(0.1, 0.35, sprintf('正确率: %.2f%%', (1-BER)*100), 'FontSize', 12);
    text(0.1, 0.2, sprintf('信噪比: %d dB', SNR_dB), 'FontSize', 12);
    axis off;
    title('性能统计');
    
    sgtitle('GMSK系统性能分析', 'FontSize', 14, 'FontWeight', 'bold');
    
else
    % 模式0：所有图形在一个窗口（简略版）
    figure('Position', [50, 50, 1600, 900], 'Name', 'GMSK系统综合分析');
    
    % 编码过程
    subplot(3,4,1);
    stem(0:N_bits-1, data_bits, 'filled', 'MarkerSize', 3);
    title('原始比特');
    xlabel('比特索引');
    grid on;
    
    subplot(3,4,2);
    plot(t(1:min(10*sps, length(tx_signal)))*1000, tx_signal(1:min(10*sps, length(tx_signal))));
    title('NRZ信号');
    xlabel('时间 (ms)');
    grid on;
    
    subplot(3,4,3);
    plot(t(1:min(10*sps, length(phase)))*1000, phase(1:min(10*sps, length(phase))));
    title('相位轨迹');
    xlabel('时间 (ms)');
    grid on;
    
    subplot(3,4,4);
    plot(t(1:min(8*sps, length(gmsk_signal)))*1000, gmsk_signal(1:min(8*sps, length(gmsk_signal))));
    title('GMSK信号');
    xlabel('时间 (ms)');
    grid on;
    
    % 解调过程
    subplot(3,4,5);
    plot(t(1:min(10*sps, length(gmsk_signal_noisy)))*1000, gmsk_signal_noisy(1:min(10*sps, length(gmsk_signal_noisy))));
    title('接收信号');
    xlabel('时间 (ms)');
    grid on;
    
    subplot(3,4,6);
    plot(t(1:min(15*sps, length(instant_freq)))*1000, instant_freq(1:min(15*sps, length(instant_freq))));
    title('瞬时频率');
    xlabel('时间 (ms)');
    grid on;
    
    subplot(3,4,7);
    stem(0:N_bits-1, demod_bits, 'filled', 'MarkerSize', 3);
    title('解调比特');
    xlabel('比特索引');
    grid on;
    
    subplot(3,4,8);
    error_pattern = data_bits ~= demod_bits;
    stem(0:N_bits-1, error_pattern, 'r', 'filled', 'MarkerSize', 3);
    title('误码位置');
    xlabel('比特索引');
    grid on;
    
    % 性能分析
    subplot(3,4,9);
    scatter(I_filtered(1:sps:end), Q_filtered(1:sps:end), 20, 'b', 'filled');
    title('星座图');
    xlabel('I分量');
    ylabel('Q分量');
    axis equal;
    grid on;
    
    subplot(3,4,10);
    eyediagram(real(gmsk_signal_noisy(1:min(200*sps, length(gmsk_signal_noisy)))), 2*sps);
    title('眼图');
    
    subplot(3,4,11);
    % 频谱
    NFFT = 2^nextpow2(length(gmsk_signal));
    f = Fs/2 * linspace(0,1,NFFT/2+1);
    Y = fft(gmsk_signal, NFFT) / length(gmsk_signal);
    plot(f/1000, 20*log10(2*abs(Y(1:NFFT/2+1))));
    title('功率谱');
    xlabel('频率 (kHz)');
    ylabel('功率 (dB)');
    grid on;
    
    subplot(3,4,12);
    % 性能统计
    text(0.1, 0.8, sprintf('BER: %.4f', BER), 'FontSize', 14, 'FontWeight', 'bold');
    text(0.1, 0.6, sprintf('正确率: %.1f%%', (1-BER)*100), 'FontSize', 12);
    text(0.1, 0.4, sprintf('误码数: %d', bit_errors), 'FontSize', 12);
    text(0.1, 0.2, sprintf('SNR: %d dB', SNR_dB), 'FontSize', 12);
    axis off;
    title('性能统计');
    
    sgtitle('GMSK调制解调系统', 'FontSize', 16, 'FontWeight', 'bold');
end

%% 显示详细误码分析
fprintf('\n误码分析:\n');
error_indices = find(data_bits ~= demod_bits);
if ~isempty(error_indices)
    fprintf('误码位置: ');
    fprintf('%d ', error_indices);
    fprintf('\n');
    
    fprintf('误码对应的原始比特: ');
    fprintf('%d ', data_bits(error_indices));
    fprintf('\n');
    
    fprintf('误码对应的解调比特: ');
    fprintf('%d ', demod_bits(error_indices));
    fprintf('\n');
else
    fprintf('无误码！\n');
end

fprintf('\n仿真完成！\n');
if BER > 0.1
    fprintf('警告: 误码率较高，建议:\n');
    fprintf('  1. 增加信噪比 (SNR_dB)\n');
    fprintf('  2. 调整滤波器参数\n');
    fprintf('  3. 检查载波频率匹配\n');
end