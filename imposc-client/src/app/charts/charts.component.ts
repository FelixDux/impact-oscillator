import { Component, OnInit } from '@angular/core';
import { Chart } from '../chart';
import { ChartService } from '../chart.service';
import { MessageService } from '../message.service';

@Component({
  selector: 'app-charts',
  templateUrl: './charts.component.html',
  styleUrls: ['./charts.component.css']
})
export class ChartsComponent implements OnInit {

charts: Chart[]; 

  constructor(private chartService: ChartService, private messageService: MessageService) { }

  ngOnInit(): void {
    this.getCharts();
  }

  getCharts(): void {
  this.chartService.getCharts()
  .subscribe(charts => this.charts = charts);  }

  selectedChart: Chart;
onSelect(chart: Chart): void {
  this.selectedChart = chart;
    this.messageService.add('ChartService: Selected chart name=${chart.name}');
}
}
