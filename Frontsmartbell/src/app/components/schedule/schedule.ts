import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { CourseCalendarComponent } from '../course-calendar/course-calendar.component';

@Component({
  selector: 'app-schedule',
  standalone: true,
  imports: [CommonModule, CourseCalendarComponent],
  templateUrl: './schedule.html',
  styleUrl: './schedule.css'
})
export class Schedule {}
