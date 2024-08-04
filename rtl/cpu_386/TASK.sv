// ============================================================================
//        __
//   \\__/ o\    (C) 2024  Robert Finch, Waterloo
//    \  __ /    All rights reserved.
//     \/_//     robfinch<remove>@finitron.ca
//       ||
//
//  Task switching code
//
// BSD 3-Clause License
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
//    list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
//    contributors may be used to endorse or promote products derived from
//    this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ============================================================================

rf80386_pkg::TASK_SWITCH:	
	begin
		selector <= new_tr;
		rrr <= 3'd6;	// tss_desc
		old_tss_desc <= tss_desc;
		tGosub(rf80386_pkg::LOAD_DESC,rf80386_pkg::TASK_SWITCH1);
	end
rf80386_pkg::TASK_SWITCH1:
	begin
		if (!tss_desc.p) begin
			int_num <= 8'd11;	//  segment not present
			tGoto(rf80386_pkg::INT2);
		end
		else begin
			casez({tss_desc.s,tss_desc.typ})
			5'b00001,	// 286 task
			5'b01001:	// 386 task
				begin
					new_tss_desc <= tss_desc;
					tss_desc <= old_tss_desc;
					tGoto(rf80386_pkg::TASK_SWITCH2);
				end
			default:
				begin
					int_num <= 8'd10;	//  invalid TSS
					tGoto(rf80386_pkg::INT2);
				end
			endcase
		end
	end
rf80386_pkg::TASK_SWITCH2:	tWriteTSSReg(eax,`TSS_EAX,1,rf80386_pkg::TASK_SWITCH3);
rf80386_pkg::TASK_SWITCH3:	tWriteTSSReg(ecx,`TSS_ECX,1,rf80386_pkg::TASK_SWITCH4);
rf80386_pkg::TASK_SWITCH4:	tWriteTSSReg(edx,`TSS_EDX,1,rf80386_pkg::TASK_SWITCH5);
rf80386_pkg::TASK_SWITCH5:	tWriteTSSReg(ebx,`TSS_EBX,1,rf80386_pkg::TASK_SWITCH6);
rf80386_pkg::TASK_SWITCH6:	tWriteTSSReg(esp,`TSS_ESP,1,rf80386_pkg::TASK_SWITCH7);
rf80386_pkg::TASK_SWITCH7:	tWriteTSSReg(ebp,`TSS_EBP,1,rf80386_pkg::TASK_SWITCH8);
rf80386_pkg::TASK_SWITCH8:	tWriteTSSReg(esi,`TSS_ESI,1,rf80386_pkg::TASK_SWITCH9);
rf80386_pkg::TASK_SWITCH9:	tWriteTSSReg(edi,`TSS_EDI,1,rf80386_pkg::TASK_SWITCH10);
rf80386_pkg::TASK_SWITCH10:	tWriteTSSReg(es,`TSS_ES,0,rf80386_pkg::TASK_SWITCH11);
rf80386_pkg::TASK_SWITCH11:	tWriteTSSReg(cs,`TSS_CS,0,rf80386_pkg::TASK_SWITCH12);
rf80386_pkg::TASK_SWITCH12:	tWriteTSSReg(ss,`TSS_SS,0,rf80386_pkg::TASK_SWITCH13);
rf80386_pkg::TASK_SWITCH13:	tWriteTSSReg(ds,`TSS_DS,0,rf80386_pkg::TASK_SWITCH14);
rf80386_pkg::TASK_SWITCH14:	tWriteTSSReg(fs,`TSS_FS,0,rf80386_pkg::TASK_SWITCH15);
rf80386_pkg::TASK_SWITCH15:	tWriteTSSReg(gs,`TSS_GS,0,rf80386_pkg::TASK_SWITCH18);
rf80386_pkg::TASK_SWITCH18:	
	if (nest_task)
		tWriteTSSReg(tr,`TSS_LINK,0,rf80386_pkg::TASK_SWITCH19);
//rf80386_pkg::TASK_SWITCH16:	tWriteTSSReg(ldt,`TSS_LDT,0,rf80386_pkg::TASK_SWITCH17);
//rf80386_pkg::TASK_SWITCH17:	tWriteTSSReg(cr3,`TSS_CR3,1,rf80386_pkg::TASK_SWITCH18);
rf80386_pkg::TASK_SWITCH18:	tWriteTSSReg(eip,`TSS_EIP,1,rf80386_pkg::TASK_SWITCH19);
rf80386_pkg::TASK_SWITCH19:	tWriteTSSReg(flags,`TSS_EFLAGS,1,rf80386_pkg::TASK_SWITCH20);

rf80386_pkg::TASK_SWITCH20:
	begin
		tr <= new_tr;
		tss_desc <= new_tss_desc;
		tGoto(rf80386_pkg::TASK_SWITCH30);
	end
rf80386_pkg::TASK_SWITCH30:	tReadTSSReg(`TSS_EAX,1,rf80386_pkg::TASK_SWITCH31);
rf80386_pkg::TASK_SWITCH31:	begin eax <= dat; tReadTSSReg(`TSS_ECX,1,rf80386_pkg::TASK_SWITCH32); end
rf80386_pkg::TASK_SWITCH32:	begin ecx <= dat; tReadTSSReg(`TSS_EDX,1,rf80386_pkg::TASK_SWITCH33); end
rf80386_pkg::TASK_SWITCH33:	begin edx <= dat; tReadTSSReg(`TSS_EBX,1,rf80386_pkg::TASK_SWITCH34); end
rf80386_pkg::TASK_SWITCH34:	begin ebx <= dat; tReadTSSReg(`TSS_ESP,1,rf80386_pkg::TASK_SWITCH35); end
rf80386_pkg::TASK_SWITCH35:	begin esp <= dat; tReadTSSReg(`TSS_EBP,1,rf80386_pkg::TASK_SWITCH36); end
rf80386_pkg::TASK_SWITCH36:	begin ebp <= dat; tReadTSSReg(`TSS_ESI,1,rf80386_pkg::TASK_SWITCH37); end
rf80386_pkg::TASK_SWITCH37:	begin esi <= dat; tReadTSSReg(`TSS_EDI,1,rf80386_pkg::TASK_SWITCH38); end
rf80386_pkg::TASK_SWITCH38:	begin edi <= dat; tReadTSSReg(`TSS_ES,0,rf80386_pkg::TASK_SWITCH39); end
rf80386_pkg::TASK_SWITCH39:	begin es <= dat[15:0]; tReadTSSReg(`TSS_CS,0,rf80386_pkg::TASK_SWITCH40); end
rf80386_pkg::TASK_SWITCH40:	begin cs <= dat[15:0]; tReadTSSReg(`TSS_SS,0,rf80386_pkg::TASK_SWITCH41); end
rf80386_pkg::TASK_SWITCH41:	begin ss <= dat[15:0]; tReadTSSReg(`TSS_DS,0,rf80386_pkg::TASK_SWITCH42); end
rf80386_pkg::TASK_SWITCH42:	begin ds <= dat[15:0]; tReadTSSReg(`TSS_FS,0,rf80386_pkg::TASK_SWITCH43); end
rf80386_pkg::TASK_SWITCH43:	begin fs <= dat[15:0]; tReadTSSReg(`TSS_GS,0,rf80386_pkg::TASK_SWITCH44); end
rf80386_pkg::TASK_SWITCH44:	begin gs <= dat[15:0]; tReadTSSReg(`TSS_LDT,0,rf80386_pkg::TASK_SWITCH45); end
rf80386_pkg::TASK_SWITCH45:	begin ldt <= dat[15:0]; tReadTSSReg(`TSS_CR3,1,rf80386_pkg::TASK_SWITCH46); end
rf80386_pkg::TASK_SWITCH46:	begin cr3 <= dat; tReadTSSReg(`TSS_EIP,1,rf80386_pkg::TASK_SWITCH47); end
rf80386_pkg::TASK_SWITCH47:	begin eip <= dat; tReadTSSReg(`TSS_EFLAGS,1,rf80386_pkg::TASK_SWITCH48); end
rf80386_pkg::TASK_SWITCH48:
	begin
		cf <= dat[0];
		pf <= dat[2];
		af <= dat[4];
		zf <= dat[6];
		sf <= dat[7];
		tf <= dat[8];
		ie <= dat[9];
		df <= dat[10];
		vf <= dat[11];
		nt <= nest_task ? 1'b1 : dat[14];
		vm <= dat[18];
		cr0[3] <= 1'b1;	// task switched flag
		tReturn();
	end
