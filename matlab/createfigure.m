function createfigure(X1, YMatrix1)
%CREATEFIGURE(X1, YMATRIX1)
%  X1:  vector of x data
%  YMATRIX1:  matrix of y data

%  Auto-generated by MATLAB on 30-Mar-2016 00:08:08

% Create figure
figure1 = figure('Color',[1 1 1]);

% Create axes
axes1 = axes('Parent',figure1,'LineWidth',2,'FontSize',16);
box(axes1,'on');
grid(axes1,'on');
hold(axes1,'on');

% Create multiple lines using matrix input to plot
plot1 = plot(X1,YMatrix1,'LineWidth',1);
set(plot1(1),'DisplayName','Client 1','Color',[1 0 0]);
set(plot1(2),'DisplayName','Client 2','Color',[0 0 1]);

% Create xlabel
xlabel({'Time (slot)'},'FontSize',17);

% Create ylabel
ylabel({'Queue length'});

% Create legend
legend1 = legend(axes1,'show');
set(legend1,...
    'Position',[0.156709959225737 0.797281326466276 0.166233763447056 0.106382975869991],...
    'FontSize',16);

