import { Component, OnInit } from '@angular/core';
import { Chart } from '../chart';
import { ChartService } from '../chart.service';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: [ './dashboard.component.css' ]
})
export class DashboardComponent implements OnInit {
  charts: Chart[] = [];

  constructor(private chartService: ChartService) { }

  ngOnInit() {
    this.getCharts();
  }

  getCharts(): void {
    this.chartService.getCharts()
      .subscribe(charts => this.charts = charts);
  }
}
