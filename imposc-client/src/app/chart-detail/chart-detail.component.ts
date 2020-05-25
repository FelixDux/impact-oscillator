import { Component, OnInit, Input } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { Location } from '@angular/common';

import { ChartService }  from '../chart.service';
import { Chart } from '../chart';

@Component({
  selector: 'app-chart-detail',
  templateUrl: './chart-detail.component.html',
  styleUrls: ['./chart-detail.component.css']
})
export class ChartDetailComponent implements OnInit {
  @Input() chart: Chart;

  constructor(
  private route: ActivatedRoute,
  private chartService: ChartService,
  private location: Location
	) {}

	ngOnInit(): void {
  this.getChart();
}

getChart(): void {
  const name = +this.route.snapshot.paramMap.get('name');
  this.chartService.getChart(name)
    .subscribe(chart => this.chart = chart);
}

goBack(): void {
  this.location.back();
}
}
