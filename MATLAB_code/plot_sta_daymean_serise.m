%% 绘制站点污染物的日均浓度变化
% version：MATLAB R2023b
clear
close all
%% basic set
% --- AQI数据存储文件夹
aqi_dir='..\';           
% --- 制图存储文件夹
fig_dir='..\fig\';
% --- 设定需要提取的时间范围 datetime(年,月,日,小时,分钟,秒)：时间分辨率：
time_series=datetime(2024,12,1):days(1):datetime(2025,3,31);
% --- 站点序号，1159A站--仙林大学城
site_num=1159;
% --- aqi_file的变量排列
var_name={'PM_{2.5}','PM_{10}','O_3','CO','SO_2','NO_2','MDA8'};
units={'\mug/m^3','\mug/m^3','\mug/m^3','mg/m^3','\mug/m^3','\mug/m^3','\mug/m^3'};
%% get data
day_len=length(time_series);       %计算分析时间点数
poll_data=nan(6,day_len);           %预分配数据矩阵空间
for i=1:day_len
    % --- get year's AQI data
    if i==1
        year_num=year(time_series(i));
        aqi_file=[aqi_dir num2str(site_num) 'A'  '\AQI_' num2str(site_num) 'A_' num2str(year_num) '.txt'];
        AQI=readmatrix(aqi_file,'Range',[2 2]);                                          %读取aqi_file数据
        nan_pos=find(AQI==-999);
        AQI(nan_pos)=NaN;
    else
        if year_num~=year(time_series(i))                   %除第一次读取数据，其余时刻仅年份发生变动再读取和处理AQI数据
            year_num=year(time_series(i));
            aqi_file=[aqi_dir num2str(site_num) 'A'  '\AQI_' num2str(site_num) 'A_' num2str(year_num) '.txt'];
            AQI=readmatrix(aqi_file,'Range',[2 2]);                                          %读取aqi_file数据
            nan_pos=find(AQI==-999);
            AQI(nan_pos)=NaN;
        end
    end
    data_pos=hours(time_series(i)-datetime(year_num,1,1,0,0,0))+1;   %计算所需要平均数据起始点在aqi_file中的位置
    poll_data(1:6,i)=mean(AQI(data_pos:data_pos+23,:),1,"omitmissing");                   %计算日平均
    poll_data(7,i)=getMDA8(AQI(data_pos:data_pos+23,3));
end

choose_kind=2;
fig1=one_line(time_series,poll_data(choose_kind,:),var_name{choose_kind},units{choose_kind},site_num);
if ~exist(fig_dir,"dir")
    mkdir(fig_dir)
end
save_fig_name=[fig_dir 'sta_' num2str(site_num) '_' var_name{choose_kind} char(time_series(1),'yyMMdd') '_' char(time_series(end),'yyMMdd') '.png'];
exportgraphics(fig1,save_fig_name,'Resolution',400);

choose_kind=[2 7];
fig2=double_line(time_series,poll_data(choose_kind(1),:),var_name{choose_kind(1)},units{choose_kind(1)},...
    poll_data(choose_kind(2),:),var_name{choose_kind(2)},units{choose_kind(2)},site_num);
save_fig_name2=[fig_dir 'sta_' num2str(site_num) '_' var_name{choose_kind(1)} '_'  var_name{choose_kind(2)} ...
    char(time_series(1),'yyMMdd') '_' char(time_series(end),'yyMMdd') '.png'];
exportgraphics(fig2,save_fig_name2,'Resolution',400);
                        
%% --- one_line --- %%
function fig=one_line(xl,data,poll_name,poll_units,site_num)
    fig=figure("OuterPosition",[150 100 1213 835]);
    fs=16;
    % --- plot data
    plot(xl,data,"LineWidth",1.2,'Marker','.','MarkerSize',10);             %Marker MarkerSize --- 使得数据点具有标记
    % --- annotate max point
    [~,max_pos]=max(data);
    if max_pos*2>length(xl)
        text(xl(max_pos),data(max_pos)+2,['max: ' num2str(data(max_pos),'%.1f') poll_units '\leftarrow' ],"FontSize",fs,"HorizontalAlignment","right");
    else
        text(xl(max_pos),data(max_pos)+2,['\rightarrow max: ' num2str(data(max_pos),'%.1f') poll_units],"FontSize",fs)
    end
    title(['AQI analysis ' poll_name ' day mean'],'FontSize',fs+1)
    subtitle(['site: ' num2str(site_num) 'A   \it' char(xl(1),'yy-MM-dd') ' to ' char(xl(end),'yy-MM-dd')],'FontSize',fs-2);
    y_label=[poll_name '(' poll_units ')'];
    ylabel(y_label,'FontSize',fs);
    grid on
    ax=gca;
    ylim([0 modify_ylim(ax.YLim(2))])
    ax.FontSize=fs;
    ax.LineWidth=1.2;
end
%% --- double_line --- %%
function fig=double_line(xl,data1,name1,unit1,data2,name2,unit2,site_num)
    fig=figure("OuterPosition",[150 100 1213 835]);
    fs=16;
    % --- plot data left
    yyaxis left
    plot(xl,data1,"LineWidth",1.2,'Marker','.','MarkerSize',10);             %Marker MarkerSize --- 使得数据点具有标记
    % --- annotate max point
    [~,max_pos]=max(data1);
    if max_pos*2>length(xl)
        text(xl(max_pos),data1(max_pos)+2,['max: ' num2str(data1(max_pos),'%.1f') unit1 '\leftarrow'],"FontSize",fs,"HorizontalAlignment","right");
    else
        text(xl(max_pos),data1(max_pos)+2,['\rightarrow max: ' num2str(data1(max_pos),'%.1f') unit1],"FontSize",fs)
    end
    y_label=[name1 '(' unit1 ')'];
    ylabel(y_label,'FontSize',fs);

    % --- plot data right
    yyaxis right
    plot(xl,data2,"LineWidth",1.2,'Marker','.','MarkerSize',10);             %Marker MarkerSize --- 使得数据点具有标记
    % --- annotate max point
    [~,max_pos]=max(data2);
    if max_pos*2>length(xl)
        text(xl(max_pos),data2(max_pos)+2,['max: ' num2str(data2(max_pos),'%.1f') unit2 '\leftarrow'],"FontSize",fs,"HorizontalAlignment","right");
    else
        text(xl(max_pos),data2(max_pos)+2,['\rightarrow max: ' num2str(data2(max_pos),'%.1f') unit2],"FontSize",fs)
    end
    y_label=[name2 '(' unit2 ')'];
    ylabel(y_label,'FontSize',fs);
    title(['AQI analysis ' name1 ' and ' name2 ' day mean'],'FontSize',fs+1);
    subtitle(['site: ' num2str(site_num) 'A   \it' char(xl(1),'yy-MM-dd') ' to ' char(xl(end),'yy-MM-dd')],'FontSize',fs-2);
    grid on
    ax=gca;
    ylim([0 modify_ylim(ax.YLim(2))])
    ax.FontSize=fs;
    ax.LineWidth=1.2;
end
%% --- modify_ylim --- %%
function ylim_max_m=modify_ylim(ylim_max)
    size10=floor(log10(ylim_max));
    y_step=floor(ylim_max/10^(size10))*10^(size10-1);
    ylim_max_m=ylim_max-mod(ylim_max,y_step)+y_step;
end
%% --- MDA8 function --- %%
function MDA8=getMDA8(O3_poll)
    %O3_poll: O3  concentration in one day
    DA8=nan(17,1);
    for i=1:17
        DA8(i)=mean(O3_poll(i:i+7));
    end
    MDA8=max(DA8);
end