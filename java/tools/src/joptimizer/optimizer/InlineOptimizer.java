/*
 * Copyright (c) 2007,2008, Stefan Hepp
 *
 * This file is part of JOPtimizer.
 *
 * JOPtimizer is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 3 of the License, or
 * (at your option) any later version.
 *
 * JOPtimizer is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package joptimizer.optimizer;

import com.jopdesign.libgraph.cfg.ControlFlowGraph;
import com.jopdesign.libgraph.struct.MethodInfo;
import joptimizer.config.BoolOption;
import joptimizer.config.JopConfig;
import joptimizer.config.StringOption;
import joptimizer.framework.JOPtimizer;
import joptimizer.framework.actions.AbstractGraphAction;
import joptimizer.framework.actions.ActionException;
import joptimizer.optimizer.inline.BottomUpInlineStrategy;
import joptimizer.optimizer.inline.CodeInliner;
import joptimizer.optimizer.inline.InlineChecker;
import joptimizer.optimizer.inline.InlineHelper;
import joptimizer.optimizer.inline.InlineStrategy;
import org.apache.log4j.Logger;

import java.util.List;

/**
 * An optimizer which inlines as many function calls as possible
 *
 * Option '..':
 * check for more 'unsafe' inlining criterias (only valid if complete transitive
 * hull is known, no dynamic classloading is performed. As the JOPizer may remove
 * unused functions, reflections will be even more unsafe.
 *
 * @author Stefan Hepp, e0026640@student.tuwien.ac.at
 */
public class InlineOptimizer extends AbstractGraphAction {

    public static final String ACTION_NAME = "inline";

    public static final String CONF_INLINE_IGNORE = "ignore";

    public static final String CONF_INLINE_CHECK = "checkcode";

    public static final String CONF_CHANGE_ACCESS = "changeaccess";

    private static final Logger logger = Logger.getLogger(InlineOptimizer.class);

    private InlineStrategy strategy;

    public InlineOptimizer(String name, JOPtimizer joptimizer) {
        super(name, joptimizer);
    }

    public void appendActionArguments(String prefix, List options) {
        options.add(new StringOption(prefix + CONF_INLINE_IGNORE,
                "Do not inline code from the given package or class prefix. Give classes as comma-separated list.",
                "packages"));
        options.add(new BoolOption(prefix + CONF_INLINE_CHECK,
                "Insert check code before inlined code to ensure correct devirtualization (NYI). " +
                "Defaults to true if dynamic class loading is assumed to be disabled."));
        options.add(new BoolOption(prefix + CONF_CHANGE_ACCESS,
                "Allow changing of access modifiers to public access to enable inlining. " +
                "Should be used with care if dynamic class loading is used."));
    }


    public String getActionDescription() {
        return "Inline and devirtualize method calls.";
    }

    public boolean doModifyClasses() {
        return true;
    }

    public boolean configure(String prefix, JopConfig config) {

        // NOTICE make strategy selectable by option
        strategy = new BottomUpInlineStrategy();

        InlineChecker checker = new InlineChecker(getJoptimizer().getAppStruct(), config.getArchConfig());
        CodeInliner inliner = new CodeInliner(getJoptimizer().getAppStruct());
        InlineHelper helper = new InlineHelper(checker, inliner, strategy.getInvokeResolver());

        strategy.setup(helper, getJoptimizer().getAppStruct(), getJopConfig());

        // configure checker and inliner
        String ignorepkg = config.getOption(prefix + CONF_INLINE_IGNORE);
        if ( ignorepkg != null && !ignorepkg.isEmpty() ) {
            ignorepkg += "," + config.getArchConfig().getNativeClassName();
        } else {
            ignorepkg = config.getArchConfig().getNativeClassName();
        }
        checker.setIgnorePrefix(ignorepkg.split(","));

        boolean checkCode = config.isEnabled(prefix + CONF_INLINE_CHECK);
        
        inliner.setInsertCheckCode(checkCode);
        checker.setUseCheckCode(checkCode);
        checker.setAssumeDynamicLoading(config.doAssumeDynamicLoading());
        checker.setChangeAccess(config.isEnabled(prefix + CONF_CHANGE_ACCESS));
        
        return true;
    }

    public void startAction() throws ActionException {
        strategy.initialize();
    }

    public void finishAction() throws ActionException {
        if (logger.isInfoEnabled()) {
            logger.info("Inlined {" + strategy.getInlineCount() + "} methods.");
        }
    }

    public int getDefaultStage() {
        return STAGE_STACK_TO_QUAD;
    }

    public int getRequiredForm() {
        return 0;
    }

    public void execute() throws ActionException {
        strategy.execute();
    }

    public void execute(MethodInfo methodInfo, ControlFlowGraph graph) throws ActionException {
        strategy.execute(methodInfo, graph);
    }

}
