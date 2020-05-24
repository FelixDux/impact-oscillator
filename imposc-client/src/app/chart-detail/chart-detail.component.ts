import { Component, OnInit, Input } from '@angular/core';
import { Chart } from '../chart';

@Component({
  selector: 'app-chart-detail',
  templateUrl: './chart-detail.component.html',
  styleUrls: ['./chart-detail.component.css']
})
export class ChartDetailComponent implements OnInit {
  @Input() chart: Chart;

  constructor() { }

  ngOnInit(): void {
  }

}
